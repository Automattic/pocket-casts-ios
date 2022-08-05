import Foundation

public enum SubscriptionStatus: Int {
    case none = 0, cancelled = 1, paid = 2, legacyPaid = 3, notPaid = 4
}

public enum SubscriptionPlatform: Int {
    case none = 0, iOS = 1, android = 2, web = 3, gift = 4

    public var toString: String {
        switch self {
        case .none:
            return "none"
        case .iOS:
            return "ios"
        case .android:
            return "android"
        case .web:
            return "web"
        case .gift:
            return "gift"
        }
    }
}

public enum SubscriptionFrequency: Int {
    case none = 0, monthly = 1, yearly = 2

    public var toString: String {
        switch self {
        case .none:
            return "none"
        case .monthly:
            return "monthly"
        case .yearly:
            return "yearly"
        }
    }
}

public enum SubscriptionType: Int {
    case none = 0, plus = 1, supporter = 2

    public var toString: String {
        switch self {
        case .none:
            return "none"
        case .plus:
            return "plus"
        case .supporter:
            return "supporter"
        }
    }
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
