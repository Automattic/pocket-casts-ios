import Foundation

// MARK: - HeadphoneControlAction

extension HeadphoneControlAction: Unlockable {
    var paidFeature: PaidFeature? {
        switch self {
        case .addBookmark:
            return .bookmarks
        default:
            return nil
        }
    }
}

// MARK: - PlayerAction

extension PlayerAction: Unlockable {
    var paidFeature: PaidFeature? {
        switch self {
        case .addBookmark:
            return .bookmarks
        default:
            return nil
        }
    }
}
