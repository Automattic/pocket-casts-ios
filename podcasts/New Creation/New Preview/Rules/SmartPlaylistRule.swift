import Foundation

enum SmartPlaylistRule: Int, CaseIterable, Identifiable {
    case podcast, episode, releaseDate, duration, downloadStatus, mediaType, starred

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

    var title: String {
        switch self {
        case .podcast:
            return L10n.podcastsPlural
        case .episode:
            return L10n.filterEpisodeStatus
        case .downloadStatus:
            return L10n.filterDownloadStatus
        case .mediaType:
            return L10n.filterMediaType
        case .releaseDate:
            return L10n.filterReleaseDate
        case .duration:
            return L10n.filterChipsDuration
        case .starred:
            return L10n.statusStarred
        }
    }
}
