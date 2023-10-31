//
//  BookPlayerWidgetUI.swift
//  BookPlayerWidgetUI
//
//  Created by Gianni Carlo on 21/11/20.
//  Copyright © 2020 Tortuga Power. All rights reserved.
//

#if os(watchOS)
import BookPlayerWatchKit
#else
import BookPlayerKit
#endif
import SwiftUI
import WidgetKit

// TODO: Setup shared watch widgets
#if os(iOS)
struct BookPlayerWidgetUI_Previews: PreviewProvider {
  static var previews: some View {
    Group {

      LastPlayedWidgetView(entry: SimpleEntry(
        date: Date(),
        title: "Test Book Title",
        relativePath: nil,
        timerSeconds: 300,
        autoplay: true
      ))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
  }
}

@main
struct BookPlayerBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    LastPlayedWidget()
    RecentBooksWidget()
    TimeListenedWidget()
  }
}
#endif
