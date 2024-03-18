import Foundation

public enum SubscriptionStatus: Int {
    case none = 0, cancelled = 1, paid = 2, legacyPaid = 3, notPaid = 4
}

public enum SubscriptionPlatform: Int {
    case none = 0, iOS = 1, android = 2, web = 3, gift = 4

    public var isPaidSubscriptionPlatform: Bool {
        switch self {
            case .iOS, .android, .web: return true
            default: return false
        }
    }
}

public enum SubscriptionFrequency: Int {
    case none = 0, monthly = 1, yearly = 2
}

public enum UpdateStatus: Int {
    case notStarted, failed, cancelled, successNoNewData, successNewData, success
}

public enum RefreshFetchResult: UInt {
    case newData = 0
    case noData = 1
    case failed = 2
}

public enum AutoAddLimitReachedAction: Int32, Codable {
    case stopAdding = 0, addToTopOnly = 1
}

// MARK: - SubscriptionType
public enum SubscriptionType: Int {
    case none = 0, plus = 1, supporter = 2
}

// MARK: - SubscriptionTier
public enum SubscriptionTier: String {
    // The none state doesn't come from the server, but it instead may send an empty string
    // This is used as the fallback value
    case none = ""

    // The values here come from the server and are case sensitive
    case plus = "Plus", patron = "Patron"
}

extension SubscriptionTier: Comparable {
    private static var tierOrder: [Self] = [.none, .plus, .patron]

    public static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        let lhsIndex = Self.tierOrder.firstIndex(of: lhs) ?? -1
        let rhsIndex = Self.tierOrder.firstIndex(of: rhs) ?? -1

        return lhsIndex < rhsIndex
    }
}

public enum PrimaryRowAction: Int32, Codable {
    case stream = 0, download = 1
}

public enum PrimaryUpNextSwipeAction: Int32, Codable {
    case playNext = 0, playLast = 1
}

public enum AppBadge: Int32, Codable {
    case off = 0, totalUnplayed = 1, newSinceLastOpened = 2, filterCount = 10
}

public enum HeadphoneControl: Int32, Codable {
    case addBookmark = 0
    case skipBack = 1
    case skipForward = 2
    case nextChapter = 3
    case previousChapter = 4
}

/// Android uses different numberic values for these, thus the specific numbers specified here. See `Old` for the original values we used.
public enum ThemeType: Int32, CaseIterable, Codable {
    case light = 0
    case dark = 1
    case extraDark = 2
    case electric = 7
    case classic = 8
    case indigo = 4
    case radioactive = 9
    case rosé = 3
    case contrastLight = 6
    case contrastDark = 5

    public init(old: Old) {
        switch old {
        case .light:
            self = .light
        case .dark:
            self = .dark
        case .extraDark:
            self = .extraDark
        case .electric:
            self = .electric
        case .classic:
            self = .classic
        case .indigo:
            self = .indigo
        case .radioactive:
            self = .radioactive
        case .rosé:
            self = .rosé
        case .contrastLight:
            self = .contrastLight
        case .contrastDark:
            self = .contrastDark
        }
    }

    public var old: Old {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .extraDark:
            return .extraDark
        case .electric:
            return .electric
        case .classic:
            return .classic
        case .indigo:
            return .indigo
        case .radioactive:
            return .radioactive
        case .rosé:
            return .rosé
        case .contrastLight:
            return .contrastLight
        case .contrastDark:
            return .contrastDark
        }
    }

    /// This Old enum provides the original Int values so we can restore and continue to save the original values.
    public enum Old: Int {
        case light = 0, dark, extraDark, electric, classic, indigo, radioactive, rosé, contrastLight, contrastDark
    }
}
