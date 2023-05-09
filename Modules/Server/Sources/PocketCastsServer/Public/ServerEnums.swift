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

public enum SubscriptionType: Int {
    case none = 0, plus = 1, supporter = 2, patron = 3
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
