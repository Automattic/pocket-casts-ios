import Combine
import PocketCastsDataModel

class BookmarkEpisodeListViewModel: BookmarkListViewModel {
    weak var episode: BaseEpisode? = nil {
        didSet {
            reload()
        }
    }

    override func reload() {
        items = episode.map { bookmarkManager.bookmarks(for: $0, sorted: sortOption) } ?? []
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
