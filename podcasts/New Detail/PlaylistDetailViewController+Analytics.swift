import Foundation
import PocketCastsUtils
import PocketCastsDataModel

protocol PlaylistTypeTrackerProvider {
    var analyticsSourceType: String { get }
    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]?)
    func track(episode: Episode, added: Bool, to playlist: EpisodeFilter, source: String?)
}

extension PlaylistTypeTrackerProvider {
    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        var playlistEventProperties = properties ?? [:]
        if FeatureFlag.playlistsRebranding.enabled {
            playlistEventProperties["filter_type"] = analyticsSourceType
        }
        Analytics.track(event, properties: playlistEventProperties)
    }

    func track(episode: Episode, added: Bool, to playlist: EpisodeFilter, source: String? = nil) {
        let properties = [
            "source": finalSourceType(from: source, added: added),
            "playlist_name": playlist.playlistName,
            "playlist_uuid": playlist.uuid,
            "episode_uuid": episode.uuid,
            "podcast_uuid": episode.podcastUuid
        ]

        if added {
            Analytics.track(.episodeAddedToList, properties: properties)
        } else {
            Analytics.track(.episodeRemovedFromList, properties: properties)
        }
    }

    private func finalSourceType(from source: String?, added: Bool) -> String {
        let finalSource = source ?? analyticsSourceType
        if finalSource == "swipe" {
            return added ? "swipe_edit" : "swipe_remove"
        }
        return finalSource
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
