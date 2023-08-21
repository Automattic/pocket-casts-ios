import Combine
import PocketCastsDataModel

class BookmarkPodcastListViewModel: BookmarkListViewModel {
    var podcast: Podcast?

    override var availableSortOptions: [BookmarkSortOption] {
        [.newestToOldest, .oldestToNewest, .episode]
    }

    init(podcast: Podcast, bookmarkManager: BookmarkManager, sortOption: BookmarkListViewModel.SortSetting) {
        self.podcast = podcast

        super.init(bookmarkManager: bookmarkManager, sortOption: sortOption)

        reload()
    }

    override func reload() {
        guard feature.isUnlocked, let podcast else {
            items = []
            return
        }

        var items = bookmarkManager.bookmarks(for: podcast, sorted: sortOption).includeEpisodes()

        if sortOption == .episode {
            items.sortByNewestEpisodeAndBookmarkTimestamp()
        }

        self.items = items
    }

    override func refresh(bookmark: Bookmark) {
        // Update the bookmark with the episode
        var episodeBookmark = bookmark
        episodeBookmark.episode = bookmarkManager.episode(for: bookmark)

        super.refresh(bookmark: episodeBookmark)
    }

    override func addListeners() {
        super.addListeners()

        bookmarkManager.onBookmarkCreated
            .filter { [weak self] event in
                self?.podcast?.uuid == event.podcast
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }
}

private extension BaseEpisode {
    var sortDate: Date? {
        publishedDate ?? addedDate
    }
}

private extension Array where Element == Bookmark {
    /// Sorts the array by episodes release date, and the bookmarks timestamp
    mutating func sortByNewestEpisodeAndBookmarkTimestamp() {
        sort(by: {
            let timestampAsc = $0.time < $1.time

            guard let date1 = $0.episode?.sortDate, let date2 = $1.episode?.sortDate else {
                return timestampAsc
            }

            // We're grouping by the episode date, so default to using the timestamp sort if the dates are equal
            if date1 == date2 {
                return timestampAsc
            }

            return date1 > date2
        })
    }
}
