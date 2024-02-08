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

public enum AutoAddLimitReachedAction: Int32 {
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
