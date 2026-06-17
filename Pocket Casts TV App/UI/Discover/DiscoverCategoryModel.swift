import PocketCastsServer

@Observable
class DiscoverCategoryModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    let category: DiscoverCategory

    var categorySection: DiscoverCategorySection?

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
        let categorySection = await discoverManager.loadDiscoverCategoryDetails(for: category)

        await MainActor.run {
            state = categorySection != nil ? .ready : .empty
            self.categorySection = categorySection
            if let podcasts = categorySection?.categoryDetails.podcasts {
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
        return categorySection?.categoryDetails.podcasts ?? []
    }

    var sposoredPodcastsUuids: Set<String> {
        return categorySection?.sponsoredPodcastsIDs ?? []
    }

    func isSponsored(podcast: DiscoverPodcast) -> Bool {
        guard let section = categorySection, let uuid = podcast.uuid else {
            return false
        }
        return section.sponsoredPodcastsIDs.contains(uuid)
    }
}
