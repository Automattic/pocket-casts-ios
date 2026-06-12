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
        Analytics.track(.discoverListImpression, properties: ["list_id": listId, "source": source])
    }

    static func podcastTapped(listId: String, podcastUuid: String, source: String) {
        Analytics.track(.discoverListPodcastTapped, properties: ["list_id": listId, "podcast_uuid": podcastUuid, "source": source])
    }

    static func episodeTapped(listId: String, podcastUuid: String?, episodeUuid: String, source: String) {
        var properties: [String: Sendable] = ["list_id": listId, "episode_uuid": episodeUuid, "source": source]
        if let podcastUuid {
            properties["podcast_uuid"] = podcastUuid
        }
        Analytics.track(.discoverListEpisodeTapped, properties: properties)
    }

    static func categoryPillTapped(_ category: DiscoverCategory, region: String?, source: String) {
        Analytics.track(.discoverCategoriesPillTapped, properties: [
            "name": category.name ?? "none",
            "region": region ?? "none",
            "id": category.id ?? -1,
            "source": source
        ])
    }
}
