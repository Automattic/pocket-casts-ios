import Foundation
import SwiftUI

extension UIColor {
    var color: Color {
        Color(self)
    }
}

extension ThemeColor {
    /// The themed tint for a navigation bar button, or `nil` when Liquid Glass is enabled so the
    /// button adopts the system glass tint instead of a flat color.
    static func navBarTint(_ color: UIColor) -> Color? {
        LiquidGlass.isEnabled ? nil : color.color
    }
}
