import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

class BookmarkRowViewModel: ObservableObject {
    let heading: String?
    let title: String
    let subtitle: String
    let playButton: String
    let episode: BaseEpisode?

    init(bookmark: Bookmark) {
        self.episode = bookmark.episode
        self.title = bookmark.title
        self.playButton = TimeFormatter.shared.playTimeFormat(time: bookmark.time)
        self.subtitle = DateFormatter.localizedString(from: bookmark.created,
                                                      dateStyle: .medium,
                                                      timeStyle: .short)

        self.heading = (bookmark.episode as? Episode).flatMap {
            $0.title
        }
    }
}
