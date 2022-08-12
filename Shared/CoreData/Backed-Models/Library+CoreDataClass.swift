//
//  Library+CoreDataClass.swift
//  BookPlayerKit
//
//  Created by Gianni Carlo on 4/23/19.
//  Copyright © 2019 Tortuga Power. All rights reserved.
//
//

import CoreData
import Foundation

@objc(Library)
public class Library: NSManagedObject, Codable {
    public var itemsArray: [LibraryItem] {
        return self.items?.array as? [LibraryItem] ?? []
    }

  public func insert(item: LibraryItem, at index: Int? = nil) {
    if let parent = item.folder {
      parent.removeFromItems(item)
      parent.updateCompletionState()
    }

    if let library = item.library {
      library.removeFromItems(item)
    }

    if let index = index {
      self.insertIntoItems(item, at: index)
    } else {
      self.addToItems(item)
    }

    self.rebuildRelativePaths(for: item)
    self.rebuildOrderRank()
  }

  public func rebuildRelativePaths(for item: LibraryItem) {
    item.relativePath = item.originalFileName

    if let folder = item as? Folder,
       let items = folder.items?.array as? [LibraryItem] {
      items.forEach({ folder.rebuildRelativePaths(for: $0) })
    }
  }

  public func rebuildOrderRank() {
    guard let items = self.items?.array as? [LibraryItem] else { return }

    for (index, item) in items.enumerated() {
      item.orderRank = Int16(index)
      try? item.fileURL?.setAppOrderRank(index)
    }
  }

    enum CodingKeys: String, CodingKey {
        case items, books, folders, lastPlayedItem, currentTheme
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      if let item = self.lastPlayedItem {
        try container.encode(item, forKey: .lastPlayedItem)
      }

      try container.encode(currentTheme, forKey: .currentTheme)
    }

    public required convenience init(from decoder: Decoder) throws {
        // Create NSEntityDescription with NSManagedObjectContext
        guard let contextUserInfoKey = CodingUserInfoKey.context,
            let managedObjectContext = decoder.userInfo[contextUserInfoKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Library", in: managedObjectContext) else {
            fatalError("Failed to decode Library")
        }
        self.init(entity: entity, insertInto: nil)

        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let book = try? values.decode(Book.self, forKey: .lastPlayedItem) {
            self.lastPlayedItem = book
        }

        currentTheme = try? values.decode(Theme.self, forKey: .currentTheme)
    }
}
