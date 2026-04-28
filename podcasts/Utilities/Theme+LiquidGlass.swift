import Foundation
import PocketCastsUtils

extension Theme {
    static var isLiquidGlass: Bool {
        guard #available(iOS 26, *) else {
            return false // Use legacy styles
        }
        return FeatureFlag.liquidGlass.enabled
    }
}
