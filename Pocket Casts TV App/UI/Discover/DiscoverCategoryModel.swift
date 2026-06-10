import PocketCastsServer

@Observable
class DiscoverCategoryModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    let category: DiscoverCategory

    var categoryDetails: DiscoverCategoryDetails?

    var coverPodcastsUuids: [String] = []

    init(category: DiscoverCategory, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.category = category
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    func load() async {
        let detail = await discoverManager.loadDiscoverCategoryDetails(for: category)

        await MainActor.run {
            state = detail != nil ? .ready : .empty
            self.categoryDetails = detail
            if let podcasts = categoryDetails?.podcasts {
                self.coverPodcastsUuids = podcasts.compactMap { $0.uuid }
            }
        }
    }

    var icon: URL? {
        guard let urlString = category.icon, let url = URL(string: urlString) else {
            return nil
        }
        return url
    }

    var name: String {
        return category.name?.localized ?? ""
    }

    var podcasts: [DiscoverPodcast] {
        return categoryDetails?.podcasts ?? []
    }
}
