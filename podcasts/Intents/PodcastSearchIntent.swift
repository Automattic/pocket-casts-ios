import AppIntents
import PocketCastsServer
import PocketCastsDataModel

enum SearchIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noResults

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noResults:
            "No results found"
        }
    }
}

struct PodcastSearchIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Podcasts"
    static var description = IntentDescription("Search for podcasts")

    @Parameter(title: "Search Term")
    var searchTerm: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search for \(\.$searchTerm)")
    }

    @MainActor 
    func perform() async throws -> some IntentResult & ReturnsValue<[PodcastEntity]> {
        guard !searchTerm.isEmpty else {
            throw SearchIntentError.noResults
        }

        let searchResults = try await PodcastSearchTask().search(term: searchTerm)

        guard !searchResults.isEmpty else {
            throw SearchIntentError.noResults
        }

        // Filter to only podcast results (exclude folders)
        let podcastResults = searchResults.filter { $0.kind == .podcast }

        guard !podcastResults.isEmpty else {
            throw SearchIntentError.noResults
        }

        let podcastEntities = podcastResults.map { PodcastEntity(searchResult: $0) }
        let topPodcast = podcastResults.first!

//        let tabBarController = SceneHelper.rootViewController() as? MainTabBarController
//        tabBarController?.navigateToDiscover(false)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastSearchRequest, object: searchTerm)
//        }

//        let dialog = IntentDialog(
//            full: "I found \(podcastResults.count) podcast results for '\(searchTerm)'. The top result is '\(topPodcast.title ?? "Unknown")' by \(topPodcast.author ?? "Unknown").",
//            supporting: "Here are your podcast search results."
//        )

        return .result(value: podcastEntities)
    }
}
