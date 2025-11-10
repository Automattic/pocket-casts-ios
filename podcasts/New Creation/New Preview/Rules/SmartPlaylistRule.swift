import Foundation
import PocketCastsUtils

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
        var value: String = ""
        switch self {
        case .podcast:
            value = L10n.podcastsPlural
        case .episode:
            value = L10n.filterEpisodeStatus.lowercased().localizedCapitalized
        case .downloadStatus:
            value = L10n.filterDownloadStatus.lowercased().localizedCapitalized
        case .mediaType:
            value = L10n.filterMediaType.lowercased().localizedCapitalized
        case .releaseDate:
            value = L10n.filterReleaseDate.lowercased().localizedCapitalized
        case .duration:
            value = L10n.filterChipsDuration.lowercased().localizedCapitalized
        case .starred:
            value = L10n.statusStarred.lowercased().localizedCapitalized
        }

        if FeatureFlag.playlistsRebranding.enabled {
            var components = value.lowercased().components(separatedBy: " ")
            if let first = components.first {
                components[0] = first.localizedCapitalized
            }
            value = components.joined(separator: " ")
        }
        return value
    }
}
