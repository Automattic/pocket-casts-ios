import Foundation
import PocketCastsUtils

enum LiquidGlass {
    static var isEnabled: Bool {
        guard FeatureFlag.liquidGlass.enabled else { return false }
        if #available(iOS 26.0, *) { return true }
        return false
    }
}

extension Constants {
    static var effectiveMiniPlayerOffset: CGFloat {
        if LiquidGlass.isEnabled {
            // The player is shown using `UITabAccessory`, so it automatically gets
            // added to bottom safe area.
            return 0
        }
        return PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
    }
}
