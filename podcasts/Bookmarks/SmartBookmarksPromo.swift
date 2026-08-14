import Foundation
import PocketCastsUtils

/// The discoverability affordances that introduce Smart Bookmarks: a tip in the player and a "New" badge
/// on the Add Bookmark row of the player's More Actions menu.
///
/// Remove this type, `FeatureFlag.smartBookmarksPromo` and their call sites when 8.22 is cut.
enum SmartBookmarksPromo {
    /// The only app versions that show the promo.
    static let versions = ["8.19", "8.20", "8.21"]

    /// Launch with `-PCSmartBookmarksPromo` (Edit Scheme ▸ Run ▸ Arguments, off by default) to show the promo in
    /// builds that aren't one of `versions`, and to show the player tip on every launch.
    static let forceLaunchArgument = "-PCSmartBookmarksPromo"

    static var isActive: Bool {
        guard FeatureFlag.smartBookmarks.enabled, FeatureFlag.smartBookmarksPromo.enabled else { return false }

        return isForced || versions.contains(runningVersion)
    }

    static var shouldShowPlayerTip: Bool {
        isActive && (Settings.shouldShowBookmarksPlayerTip || isForced)
    }

    static var isForced: Bool {
        ProcessInfo.processInfo.arguments.contains(forceLaunchArgument)
    }

    /// The running app version as MAJOR.MINOR, so patch releases such as 8.19.1 still count as 8.19.
    ///
    /// Listing the versions rather than comparing bounds keeps the check away from string ordering, where "8.9" sorts after "8.19".
    private static var runningVersion: String {
        Settings.appVersion().split(separator: ".").prefix(2).joined(separator: ".")
    }
}
