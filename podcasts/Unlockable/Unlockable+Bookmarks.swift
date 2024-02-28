import Foundation
import PocketCastsDataModel

/// Defines the feature in this file that can be unlocked
private let UnlockableFeature = PaidFeature.bookmarks

// MARK: - HeadphoneControlAction

extension HeadphoneControlAction: Unlockable {
    var paidFeature: PaidFeature? {
        switch self {
        case .addBookmark:
            return UnlockableFeature
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
            return UnlockableFeature
        default:
            return nil
        }
    }
}
