import Foundation
import UIKit

enum LiquidGlass {
    static var isEnabled: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }
}

extension UIWindow {
    /// Forces the window's interface style to match the active in-app theme so the
    /// Liquid Glass material renders with the right tint immediately, instead of
    /// briefly flashing the system appearance before the app's appearance overrides land.
    /// Read the actual system appearance via `view.systemUserInterfaceStyle` instead of
    /// `traitCollection.userInterfaceStyle`, which reflects this override.
    func applyInterfaceStyleForActiveTheme() {
        guard LiquidGlass.isEnabled else { return }
        overrideUserInterfaceStyle = Theme.sharedTheme.activeTheme.isDark ? .dark : .light
    }
}

extension Theme {
    /// True if the *system* (not the in-app theme) is currently in dark mode.
    /// Captured at scene setup before we override the window, and refreshed in
    /// `MainTabBarController.traitCollectionDidChange`. Reads must come from the
    /// window scene's trait collection, since per-window `overrideUserInterfaceStyle`
    /// would otherwise pollute it.
    static var systemIsDark: Bool = false
}

extension Constants {
    static var effectiveMiniPlayerOffset: CGFloat {
        if LiquidGlass.isEnabled {
            // The player is shown using `UITabAccessory`, so it automatically gets
            // added to bottom safe area.
            return 0
        }
        return PlaybackManager.shared.currentEpisode == nil ? 0 : Constants.Values.miniPlayerOffset
    }

    static var effectiveFooterViewPadding: CGFloat {
        Constants.effectiveMiniPlayerOffset + (LiquidGlass.isEnabled ? 4 : 16)
    }
}
