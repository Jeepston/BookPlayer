import BookPlayerKit
import Foundation

class VoiceOverService {
    var title: String?
    var subtitle: String?
    var type: SimpleItemType!
    var progress: Double?

    // MARK: - BookCellView

    public func bookCellView(type: SimpleItemType, title: String?, subtitle: String?, progress: Double?) -> String {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.progress = progress

        switch type {
        case .book:
          return self.bookText()
        case .folder:
          return self.regularFolderText()
        case .bound:
          return self.boundFolderText()
        }
    }

    fileprivate func bookText() -> String {
        let voiceOverTitle = self.title ?? "voiceover_no_title".localized
        let voiceOverSubtitle = self.subtitle ?? "voiceover_no_author".localized
        return String.localizedStringWithFormat("voiceover_book_progress".localized, voiceOverTitle, voiceOverSubtitle, self.progressPercent())
    }

    fileprivate func fileText() -> String {
        let voiceOverTitle = self.title ?? "voiceover_no_file_title".localized
        let voiceOverSubtitle = self.subtitle ?? "voiceover_no_file_subtitle".localized
        return "\(voiceOverTitle) \(voiceOverSubtitle)"
    }

  fileprivate func regularFolderText() -> String {
    let voiceOverTitle = self.title ?? "voiceover_no_playlist_title".localized
    return String.localizedStringWithFormat("voiceover_playlist_progress".localized, voiceOverTitle, self.progressPercent())
  }

  fileprivate func boundFolderText() -> String {
      let voiceOverTitle = self.title ?? "voiceover_no_bound_books_title".localized
      return String.localizedStringWithFormat("voiceover_bound_books_progress".localized, voiceOverTitle, self.progressPercent())
  }

    fileprivate func progressPercent() -> Int {
      guard let progress = progress, !progress.isNaN, !progress.isInfinite else {
        return 0
      }
      return Int(progress)
    }

    // MARK: PlayerMetaView

    public func playerMetaText(
      title: String,
      author: String
    ) -> String {
      return String(describing: String.localizedStringWithFormat("voiceover_book_info".localized, title, author))
    }

    // MARK: - ArtworkControl

    public static func rewindText() -> String {
        return String(describing: String.localizedStringWithFormat("voiceover_rewind_time".localized, self.secondsToMinutes(PlayerManager.rewindInterval.rounded())))
    }

    public static func fastForwardText() -> String {
        return String(describing: String.localizedStringWithFormat("voiceover_forward_time".localized, self.secondsToMinutes(PlayerManager.forwardInterval.rounded())))
    }

    public static func secondsToMinutes(_ interval: TimeInterval) -> String {
        let absInterval = abs(interval)
        let hours = (absInterval / 3600.0).rounded(.towardZero)
        let minutes = (absInterval.truncatingRemainder(dividingBy: 3600) / 60).rounded(.towardZero)
        let seconds = absInterval.truncatingRemainder(dividingBy: 60).truncatingRemainder(dividingBy: 60).rounded()

        let hoursText = self.pluralization(amount: Int(hours), interval: .hour)
        let minutesText = self.pluralization(amount: Int(minutes), interval: .minute)
        let secondsText = self.pluralization(amount: Int(seconds), interval: .second)

        return String("\(hoursText)\(minutesText)\(secondsText)".dropLast())
    }

    private static func pluralization(amount: Int, interval: TimeUnit) -> String {
        switch amount {
        case 1:
            return "\(amount) \(interval.rawValue) "
        case amount where amount > 1:
            return "\(amount) \(interval.rawValue)s "
        default:
            return ""
        }
    }
}

private enum TimeUnit: String {
    case minute
    case second
    case hour
}
