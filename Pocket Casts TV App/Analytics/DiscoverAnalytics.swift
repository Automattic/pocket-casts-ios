import PocketCastsServer

/// Centralizes the tvOS Discover list analytics events.
///
/// These reuse the iOS `discover_list_*` / `discover_categories_pill_tapped` event
/// names but add a `source` ("home" or "search") so we can tell whether the
/// interaction happened on the Home tab or in Search, since tvOS has no dedicated
/// Discover screen and no `AnalyticsSourceProvider` to merge a source automatically.
enum DiscoverAnalytics {

    /// Source token for Discover content shown on the Home tab.
    static let homeSource = "home"

    /// Source token for Discover content shown in Search (when no query is active).
    static let searchSource = "search"

    static func listImpression(listId: String, source: String) {
        AnalyticsHelper.listImpression(listId: listId, category: nil, source: source)
    }

    static func podcastTapped(listId: String, podcastUuid: String, dateTime: String? = nil, source: String) {
        AnalyticsHelper.podcastTappedFromList(listId: listId, podcastUuid: podcastUuid, listDateTime: dateTime, source: source)
    }

    static func episodeTapped(listId: String, podcastUuid: String?, episodeUuid: String, source: String) {
        var properties: [String: Sendable] = ["list_id": listId, "episode_uuid": episodeUuid, "source": source]
        if let podcastUuid {
            properties["podcast_uuid"] = podcastUuid
        }
        AnalyticsHelper.podcastEpisodeTapped(fromList: listId, podcastUuid: podcastUuid ?? "", episodeUuid: episodeUuid, source: source)
    }

    static func categoryPillTapped(_ category: DiscoverCategory, region: String?, source: String) {
        Analytics.track(.discoverCategoriesPillTapped, properties: [
            "name": category.name ?? "none",
            "region": region ?? "none",
            "id": category.id ?? -1,
            "source": source
        ])
    }

    static func adTapped(categoryName: String?, region: String?, podcastUUID: String, categoryID: Int?) {
        AnalyticsHelper.adTapped(categoryName: categoryName ?? "unknown", region: region ?? "unknown", podcastUUID: podcastUUID, categoryID: categoryID ?? 0)
    }

    static var currentFeaturedPodcast: String?

    static func discoverPodcastSubscribed(podcastUuid: String) {
        Task {
            if let listID = await DiscoverManager.shared.listIdForPodcast(podcastUuid) {
                AnalyticsHelper.podcastSubscribedFromList(listId: listID, podcastUuid: podcastUuid, listDateTime: nil)
            }
            let isFeatured = currentFeaturedPodcast == podcastUuid
            if isFeatured {
                Analytics.track(.discoverFeaturedPodcastSubscribed, properties: ["podcast_uuid": podcastUuid])
                AnalyticsHelper.subscribedToFeaturedPodcast()
            }
        }
    }

    static func discoverPodcastPlayed(podcastUuid: String, listID: String? = nil) {
        Task {
            var solvedListID = listID
            if solvedListID == nil {
                solvedListID = await DiscoverManager.shared.listIdForPodcast(podcastUuid)
            }
            if let listID = solvedListID {
                AnalyticsHelper.podcastEpisodePlayedFromList(listId: listID, podcastUuid: podcastUuid)
            }
        }
    }
}
