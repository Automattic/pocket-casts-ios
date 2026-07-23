import Foundation

enum SearchDisplayMode: String, AnalyticsDescribable, CaseIterable, Identifiable {
    case allResults
    case podcasts
    case episodes

    var analyticsDescription: String {
        rawValue
    }

    var id: String {
        rawValue
    }

    var localizedDescription: String {
        switch self {
            case .allResults:
                return L10n.allResults
            case .podcasts:
                return L10n.podcastsPlural
            case .episodes:
                return L10n.episodes
        }
    }
}
