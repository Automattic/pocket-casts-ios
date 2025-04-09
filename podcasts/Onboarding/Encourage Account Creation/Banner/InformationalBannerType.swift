import Foundation

enum InformationalBannerType: String, CaseIterable {
    case filters
    case listenHistory
    case profile

    var iconName: String {
        switch self {
        case .filters:
            return "eac_filters_banner"
        case .listenHistory:
            return "eac_listening_history_banner"
        case .profile:
            return "eac_profile_banner"
        }
    }

    var title: String {
        switch self {
        case .filters:
            return L10n.eacInformationalBannerFiltersTitle
        case .listenHistory:
            return L10n.eacInformationalBannerListeningHistoryTitle
        case .profile:
            return L10n.eacInformationalBannerProfileTitle
        }
    }

    var description: String {
        switch self {
        case .filters:
            return L10n.eacInformationalBannerFiltersDescription
        case .listenHistory:
            return L10n.eacInformationalBannerListeningHistoryDescription
        case .profile:
            return L10n.eacInformationalBannerProfileDescription
        }
    }
}
