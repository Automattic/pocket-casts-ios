import Foundation
import PocketCastsUtils

enum SmartPlaylistRule: Int, CaseIterable, Identifiable {
    case podcast, duration, episode, releaseDate, downloadStatus, mediaType, starred

    var id: Int { rawValue }

    var iconName: String {
        switch self {
        case .podcast:
            return "filter_podcasts"
        case .episode:
            return "filter_play"
        case .downloadStatus:
            return "filter_downloaded"
        case .mediaType:
            return "filter_headphones"
        case .releaseDate:
            return "filter_calendar"
        case .duration:
            return "filter_clock"
        case .starred:
            return "filter_starred"
        }
    }

    var isMenuCompatible: Bool {
        guard FeatureFlag.liquidGlass.enabled else { return false }
        switch self {
        case .releaseDate, .downloadStatus, .mediaType, .starred:
            return true
        case .podcast, .duration, .episode:
            return false
        }
    }

    var title: String {
        var value: String = ""
        switch self {
        case .podcast:
            value = L10n.podcastsPlural
        case .episode:
            value = L10n.filterEpisodeStatus
        case .downloadStatus:
            value = L10n.filterDownloadStatus
        case .mediaType:
            value = L10n.filterMediaType
        case .releaseDate:
            value = L10n.filterReleaseDate
        case .duration:
            value = L10n.filterChipsDuration
        case .starred:
            value = L10n.statusStarred
        }
        if FeatureFlag.playlistsRebranding.enabled {
            value = value.sentenceCased
        }

        return value
    }
}
