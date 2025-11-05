import Foundation
import PocketCastsUtils

protocol PlaylistTypeTrackerProvider {
    var analyticsSourceType: String { get }
    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]?)
}

extension PlaylistTypeTrackerProvider {
    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        var playlistEventProperties = properties ?? [:]
        if FeatureFlag.playlistsRebranding.enabled {
            playlistEventProperties["filter_type"] = analyticsSourceType
        }
        Analytics.track(event, properties: playlistEventProperties)
    }
}

extension PlaylistDetailViewController: AnalyticsSourceProvider, PlaylistTypeTrackerProvider {
    var analyticsSource: AnalyticsSource {
        .filters
    }

    var analyticsSourceType: String {
        viewModel.isManualPlaylist ? "manual" : "smart"
    }
}
