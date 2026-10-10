import UIKit
import PocketCastsUtils

enum ReleaseDateFilterOption: Int32, AnalyticsDescribable {
    case anytime = 0
    case last24hours = 24
    case last3Days = 72
    case lastWeek = 168
    case last2Weeks = 336
    case lastMonth = 744

    var description: String {
        switch self {
        case .anytime:
            return L10n.filterReleaseDateAnytime
        case .last24hours:
            return L10n.filterReleaseDateLast24Hours
        case .last3Days:
            return L10n.filterReleaseDateLast3Days
        case .lastWeek:
            return L10n.filterReleaseDateLastWeek
        case .last2Weeks:
            return L10n.filterReleaseDateLast2Weeks
        case .lastMonth:
            return L10n.filterReleaseDateLastMonth
        }
    }

    var analyticsDescription: String {
        switch self {
        case .anytime:
            return "anytime"
        case .last24hours:
            return "24_hours"
        case .last3Days:
            return "3_days"
        case .lastWeek:
            return "last_week"
        case .last2Weeks:
            return "last_2_weeks"
        case .lastMonth:
            return "last_month"
        }
    }
}
