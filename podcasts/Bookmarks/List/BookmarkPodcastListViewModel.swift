import Combine
import PocketCastsDataModel

class BookmarkPodcastListViewModel: BookmarkListViewModel {
    weak var podcast: Podcast?

    init(podcast: Podcast, bookmarkManager: BookmarkManager, sortOption: BookmarkListViewModel.SortSetting) {
        self.podcast = podcast

        super.init(bookmarkManager: bookmarkManager, sortOption: sortOption)

        reload()
    }

    override func reload() {
        super.reload()

        items = podcast.map { bookmarkManager.bookmarks(for: $0, sorted: sortOption).includeEpisodes() } ?? []
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

    func dismiss() {
        router?.dismissBookmarksList()
    }
}
