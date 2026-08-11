import Foundation
import PocketCastsUtils

/// The discoverability affordances that introduce Smart Bookmarks: a tip in the player and a "New" badge
/// on the Add Bookmark row of the player's More Actions menu.
enum SmartBookmarksPromo {
    /// The only app version that shows the promo.
    static let version = "8.19"

    /// Launch with `-PCSmartBookmarksPromo` (Edit Scheme ▸ Run ▸ Arguments, off by default) to show the promo in
    /// builds that aren't `version`, and to show the player tip on every launch.
    static let forceLaunchArgument = "-PCSmartBookmarksPromo"

    static var isActive: Bool {
        guard FeatureFlag.smartBookmarks.enabled else { return false }

        return isForced || runningVersion == version
    }

    static var shouldShowPlayerTip: Bool {
        isActive && (Settings.shouldShowBookmarksPlayerTip || isForced)
    }

    static var isForced: Bool {
        ProcessInfo.processInfo.arguments.contains(forceLaunchArgument)
    }

    /// The running app version as MAJOR.MINOR, so patch releases such as 8.19.1 still count as 8.19.
    private static var runningVersion: String {
        Settings.appVersion().split(separator: ".").prefix(2).joined(separator: ".")
    }
}
