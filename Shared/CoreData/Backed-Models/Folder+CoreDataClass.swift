//
//  Playlist+CoreDataClass.swift
//  BookPlayerKit
//
//  Created by Gianni Carlo on 4/23/19.
//  Copyright © 2019 Tortuga Power. All rights reserved.
//
//

import CoreData
import Foundation
import UIKit

@objc(Folder)
public class Folder: LibraryItem {
    var cachedDuration: Double?
    var cachedProgress: Double?

    // MARK: - Init

  public convenience init(title: String, context: NSManagedObjectContext) {
    let entity = NSEntityDescription.entity(forEntityName: "Folder", in: context)!
    self.init(entity: entity, insertInto: context)

    self.identifier = "\(title)\(Date().timeIntervalSince1970)"
    self.relativePath = title
    self.title = title
    self.originalFileName = title
  }

  public convenience init(from fileURL: URL, context: NSManagedObjectContext) {
    let entity = NSEntityDescription.entity(forEntityName: "Folder", in: context)!
    self.init(entity: entity, insertInto: context)

    let fileTitle = fileURL.lastPathComponent
    self.identifier = "\(fileTitle)\(Date().timeIntervalSince1970)"
    self.relativePath = fileURL.relativePath(to: DataManager.getProcessedFolderURL())
    self.title = fileTitle
    self.originalFileName = fileTitle
  }

    // MARK: - Methods

    public func resetCachedProgress() {
        self.cachedProgress = nil
        self.cachedDuration = nil
        self.folder?.resetCachedProgress()
    }

    func totalDuration() -> Double {
        guard let items = self.items?.array as? [LibraryItem] else {
            return 0.0
        }

        let totalDuration = items.reduce(0.0, {$0 + $1.duration})

        guard totalDuration > 0 else {
            return 0.0
        }

        return totalDuration
    }

    public override var duration: Double {
        get {
            let itemTime = self.getProgressAndDuration()
            return itemTime.duration
        }
        set {
            super.duration = newValue
        }
    }

    public override var progress: Double {
        let itemTime = self.getProgressAndDuration()

        return itemTime.progress
    }

    public override var progressPercentage: Double {
      switch self.type {
      case .regular:
        let itemTime = self.getProgressAndDuration()

        return itemTime.progress / itemTime.duration
      case .bound:
        guard self.duration > 0 else { return 0 }

        return self.currentTime / self.duration
      }
    }

  public override func getFolder(matching relativePath: String) -> Folder? {
    if self.relativePath == relativePath {
      return self
    } else {
      return self.folder?.getFolder(matching: relativePath)
    }
  }

    public func getProgressAndDuration() -> (progress: Double, duration: Double) {
        if let cachedProgress = self.cachedProgress,
           let cachedDuration = self.cachedDuration {
            return (cachedProgress, cachedDuration)
        }

        guard let items = self.items?.array as? [LibraryItem] else {
            return (0.0, 0.0)
        }

        var totalDuration = 0.0
        var totalProgress = 0.0

        for item in items {
            totalDuration += item.duration
            totalProgress += item.isFinished
                ? item.duration
                : item.progress
        }

        self.cachedProgress = totalProgress
        self.cachedDuration = totalDuration

        guard totalDuration > 0 else {
            return (0.0, 0.0)
        }

        return (totalProgress, totalDuration)
    }

    public func updateCompletionState() {
        self.resetCachedProgress()
        guard let items = self.items?.array as? [LibraryItem] else { return }

        self.isFinished = !items.contains(where: { !$0.isFinished })
    }

    public func hasBooks() -> Bool {
        guard let books = self.items else {
            return false
        }

        return books.count > 0
    }

    public override func setCurrentTime(_ time: Double) {
        guard let items = self.items?.array as? [LibraryItem] else { return }

        for item in items {
            item.setCurrentTime(time)
        }
    }

  override public func index(for item: LibraryItem) -> Int? {
    guard let items = self.items?.array as? [LibraryItem] else {
      return nil
    }

    return items.firstIndex { (libraryItem) -> Bool in
      if let book = libraryItem as? Book {
        return book.relativePath == item.relativePath
      } else if let folder = libraryItem as? Folder {
        return folder.index(for: item) != nil
      }

      return false
    }
  }

    override public func getItem(with relativePath: String) -> LibraryItem? {
        guard let items = self.items?.array as? [LibraryItem] else {
            return nil
        }

        var itemFound: LibraryItem?

        for item in items {
            if let libraryItem = item.getItem(with: relativePath) {
                itemFound = libraryItem
                break
            }
        }

        return itemFound
    }

    public func itemIndex(with relativePath: String) -> Int? {
        guard let items = self.items?.array as? [LibraryItem] else {
            return nil
        }

        return items.firstIndex { (item) -> Bool in
            if let book = item as? Book {
                return book.relativePath == relativePath
            } else if let folder = item as? Folder {
                return folder.getItem(with: relativePath) != nil
            }

            return false
        }
    }

    public func getBook(at index: Int) -> LibraryItem? {
        guard let items = self.items?.array as? [LibraryItem] else {
            return nil
        }

        return items[index]
    }

    // Used for manual autoplay
    public override func getBookToPlay() -> Book? {
        guard let books = self.items else { return nil }

        for item in books {
            if let book = item as? Book,
               !book.isFinished {
                return book
            } else if let folder = item as? Folder {
              if let book = folder.getBookToPlay() {
                return book
              }
            }
        }

        return nil
    }

  func getPreviousBook(before relativePath: String) -> Book? {
    guard let items = self.items?.array as? [LibraryItem] else {
      return nil
    }

    guard let indexFound = self.itemIndex(with: relativePath) else {
      return nil
    }

    let targetIndex = indexFound - 1

    for (index, item) in items.enumerated() {
      guard index == targetIndex else { continue }

      if item.isFinished {
        item.setCurrentTime(0.0)
      }

      if let book = item as? Book {
        return book
      } else if let folder = item as? Folder {
        return folder.getPreviousBook(before: relativePath)
      }
    }

    return nil
  }

    // Used for player autoplay
    func getNextBook(after relativePath: String) -> Book? {
        guard let items = self.items?.array as? [LibraryItem] else {
            return nil
        }

        let indexFound = self.itemIndex(with: relativePath)

        for (index, item) in items.enumerated() {
          if let indexFound = indexFound {
            guard index > indexFound else { continue }
          }

          if item.isFinished {
            item.setCurrentTime(0.0)
          }

          if let book = item as? Book {
            return book
          } else if let folder = item as? Folder {
            return folder.getNextBook(after: relativePath)
          }
        }

        return nil
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
    item.relativePath = self.relativePathBuilder(for: item)

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

    public func relativePathBuilder(for item: LibraryItem) -> String {
        let itemRelativePath = item.relativePath.split(separator: "/").map({ String($0) }).last ?? item.relativePath

        return "\(self.relativePath!)/\(itemRelativePath!)"
    }

  public override func info() -> String {
    let count = self.items?.array.count ?? 0

    return String.localizedStringWithFormat("files_title".localized, count)
  }

    enum CodingKeys: String, CodingKey {
        case title, desc, books, folders, library, orderRank, items
    }

    public override func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(title, forKey: .title)
      try container.encode(desc, forKey: .desc)
      try container.encode(orderRank, forKey: .orderRank)

      guard let itemsArray = self.items?.array as? [LibraryItem] else { return }

      try container.encode(itemsArray, forKey: .items)
    }

    public required convenience init(from decoder: Decoder) throws {
      // Create NSEntityDescription with NSManagedObjectContext
      guard let contextUserInfoKey = CodingUserInfoKey.context,
            let managedObjectContext = decoder.userInfo[contextUserInfoKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Folder", in: managedObjectContext) else {
              fatalError("Failed to decode Folder!")
            }
      self.init(entity: entity, insertInto: nil)

      let values = try decoder.container(keyedBy: CodingKeys.self)
      title = try values.decode(String.self, forKey: .title)
      desc = try values.decode(String.self, forKey: .desc)

      if let encodedItems = try? values.decode([LibraryItem].self, forKey: .items) {
        items = NSOrderedSet(array: encodedItems)
      }
    }
}
