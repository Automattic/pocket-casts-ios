import Foundation

// MARK: - SettingValue

/// This adds support for `Unlockable` `SettingValue`'s and provides a way for callers to retrieve the easily get the
/// setting value which defaults to `defaultValue` if the feature is locked.
extension Constants.SettingValue: Unlockable {
    var paidFeature: PaidFeature? {
        (value as? Unlockable)?.paidFeature
    }

    /// Defaults to returning the default value if the setting is not unlocked
    var unlockedValue: Value {
        isUnlocked ? value : defaultValue
    }
}

// MARK: - HeadphoneControlAction + Bookmarks

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
