import Foundation

enum InformationalBannerType: String, CaseIterable {
    case filters
    case listeningHistory
    case profile
    case playlists

    var iconName: String {
        switch self {
        case .filters, .playlists:
            return "eac_filters_banner"
        case .listeningHistory:
            return "eac_listening_history_banner"
        case .profile:
            return "eac_profile_banner"
        }
    }

    var title: String {
        switch self {
        case .filters:
            return L10n.eacInformationalBannerFiltersTitle
        case .listeningHistory:
            return L10n.eacInformationalBannerListeningHistoryTitle
        case .profile:
            return L10n.eacInformationalBannerProfileTitle
        case .playlists:
            return L10n.eacInformationalBannerPlaylistsTitle
        }
    }

    var description: String {
        switch self {
        case .filters:
            return L10n.eacInformationalBannerFiltersDescription
        case .listeningHistory:
            return L10n.eacInformationalBannerListeningHistoryDescription
        case .profile:
            return L10n.eacInformationalBannerProfileDescription
        case .playlists:
            return L10n.eacInformationalBannerPlaylistsDescription
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .filters:
            return L10n.eacInformationalBannerFiltersIconAccessibility
        case .listeningHistory:
            return L10n.eacInformationalBannerListeningHistoryIconAccessibility
        case .profile:
            return L10n.eacInformationalBannerProfileIconAccessibility
        case .playlists:
            return L10n.eacInformationalBannerPlaylistsIconAccessibility
        }
    }
}
