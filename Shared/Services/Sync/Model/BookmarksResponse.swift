//
//  BookmarksResponse.swift
//  BookPlayer
//
//  Created by gianni.carlo on 26/4/23.
//  Copyright © 2023 Tortuga Power. All rights reserved.
//

import Foundation

struct BookmarksResponse: Decodable {
  let bookmarks: [SyncableBookmark]
}
