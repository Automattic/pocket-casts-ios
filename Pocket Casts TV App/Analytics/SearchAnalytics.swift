import PocketCastsServer

/// Centralizes the tvOS `search_result_tapped` event so every surface that renders a
/// search result — the grids, the `Top Results` rows and the `Featured` row — reports
/// the same `result_type` for the same kind of result.
enum SearchAnalytics {

    static let source = "search"

    static func episodeTapped(_ episode: EpisodeSearchResult) {
        AnalyticsPlaybackHelper.shared.currentSource = .search
        Analytics.track(.searchResultTapped, properties: [
            "source": source,
            "uuid": episode.uuid,
            "result_type": "episode"
        ])
    }

    static func podcastTapped(_ podcast: PodcastFolderSearchResult) {
        Analytics.track(.searchResultTapped, properties: [
            "source": source,
            "uuid": podcast.uuid,
            "result_type": podcast.isLocal == true ? "podcast_local_result" : "podcast_remote_result"
        ])
    }
}
