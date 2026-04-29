import Foundation
import PocketCastsUtils

enum LiquidGlass {
    static var isEnabled: Bool {
        guard FeatureFlag.liquidGlass.enabled else { return false }
        if #available(iOS 26.0, *) { return true }
        return false
    }
}
