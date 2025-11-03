import Foundation

extension PlaylistDetailViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .filters
    }

    var analyticsSourceType: String {
        viewModel.isManualPlaylist ? "manual" : "smart"
    }

    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        var playlistEventProperties = properties ?? [:]
        playlistEventProperties["filter_type"] = analyticsSourceType

        Analytics.track(event, properties: playlistEventProperties)
    }
}
