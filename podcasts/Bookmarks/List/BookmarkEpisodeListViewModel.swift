import Combine
import PocketCastsDataModel
import SwiftUI

class BookmarkEpisodeListViewModel: BookmarkListViewModel {
    var episode: BaseEpisode? = nil {
        didSet {
            reload()
        }
    }

    convenience init(episode: BaseEpisode, bookmarkManager: BookmarkManager, sortOption: Binding<BookmarkSortOption>) {
        self.init(bookmarkManager: bookmarkManager, sortOption: sortOption)

        self.episode = episode
        reload()
    }

    /// The list is already shown within its own episode, so a tap on the artwork opens the bookmark instead
    override func episodeTapped(_ episode: BaseEpisode, for bookmark: Bookmark) {
        guard episode.uuid != self.episode?.uuid else {
            tapped(item: bookmark)
            return
        }

        super.episodeTapped(episode, for: bookmark)
    }

    override func reload() {
        guard feature.isUnlocked, let episode else {
            items = []
            return
        }

        items = bookmarkManager.bookmarks(for: episode, sorted: sortOption)
    }

    override func addListeners() {
        super.addListeners()

        bookmarkManager.onBookmarkCreated
            .filter { [weak self] event in
                self?.episode?.uuid == event.episode
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }
}
