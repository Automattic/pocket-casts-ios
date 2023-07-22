import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

class BookmarkRowViewModel: ObservableObject {
    let bookmark: Bookmark
    private let imageManager: ImageManager

    @Published var episodeImage: UIImage? = nil

    let heading: String?
    let title: String
    let subtitle: String
    let playButton: String

    init(bookmark: Bookmark, imageManager: ImageManager = .sharedManager) {
        self.imageManager = imageManager

        self.bookmark = bookmark
        self.title = bookmark.title
        self.playButton = TimeFormatter.shared.playTimeFormat(time: bookmark.time)
        self.subtitle = DateFormatter.localizedString(from: bookmark.created,
                                                      dateStyle: .medium,
                                                      timeStyle: .short)

        guard let episode = bookmark.episode else {
            self.heading = nil
            return
        }

        _episodeImage = .init(initialValue: imageManager.placeHolderImage(.list))

        self.heading = (episode as? Episode).flatMap {
            $0.title
        }

        loadImage(for: episode)
    }

    private func loadImage(for episode: BaseEpisode) {
        imageManager.imageForEpisode(episode, size: .list) { [weak self] image in
            self?.episodeImage = image
        }
    }
}
