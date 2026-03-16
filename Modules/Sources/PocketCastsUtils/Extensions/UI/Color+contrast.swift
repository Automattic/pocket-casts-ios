import SwiftUI

extension Color {
    #if !os(watchOS)
    /// Return the contrast between the current color and a given one
    ///
    /// - Parameters:
    ///   - with: The `Color` to be compared against
    public func contrast(with color: Color) -> CGFloat {
        let luminance1 = luminance()
        let luminance2 = color.luminance()

        let luminanceDarker = min(luminance1, luminance2)
        let luminanceLighter = max(luminance1, luminance2)

        return (luminanceLighter + 0.05) / (luminanceDarker + 0.05)
    }

    public func luminance() -> CGFloat {
        let ciColor = CIColor(color: UIColor(self))

        func adjust(colorComponent: CGFloat) -> CGFloat {
            return (colorComponent < 0.04045) ? (colorComponent / 12.92) : pow((colorComponent + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * adjust(colorComponent: ciColor.red) + 0.7152 * adjust(colorComponent: ciColor.green) + 0.0722 * adjust(colorComponent: ciColor.blue)
    }
    #endif
}
