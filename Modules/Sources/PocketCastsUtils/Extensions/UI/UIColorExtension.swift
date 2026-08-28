
import UIKit

public extension UIColor {
    convenience init(hex: String) {
        let components = UIColor.components(hex: hex) ?? (red: 0, green: 0, blue: 0, alpha: 1)
        self.init(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }

    /// The color `hex` describes, or `nil` when it isn't `#RGB`, `#RGBA`, `#RRGGBB` or `#RRGGBBAA`.
    ///
    /// Unlike ``init(hex:)``, which falls back to black, this lets a caller fall back to a theme color
    /// when a server sends a blank or malformed value.
    static func from(hex: String) -> UIColor? {
        guard let components = components(hex: hex) else { return nil }
        return UIColor(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }

    private static func components(hex: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        guard hex.hasPrefix("#") else { return nil }

        let hexString = String(hex.dropFirst())
        var hexValue: CUnsignedLongLong = 0
        guard hexString.allSatisfy(\.isHexDigit), Scanner(string: hexString).scanHexInt64(&hexValue) else { return nil }

        switch hexString.count {
        case 3:
            return (red: CGFloat((hexValue & 0xF00) >> 8) / 15.0,
                    green: CGFloat((hexValue & 0x0F0) >> 4) / 15.0,
                    blue: CGFloat(hexValue & 0x00F) / 15.0,
                    alpha: 1.0)
        case 4:
            return (red: CGFloat((hexValue & 0xF000) >> 12) / 15.0,
                    green: CGFloat((hexValue & 0x0F00) >> 8) / 15.0,
                    blue: CGFloat((hexValue & 0x00F0) >> 4) / 15.0,
                    alpha: CGFloat(hexValue & 0x000F) / 15.0)
        case 6:
            return (red: CGFloat((hexValue & 0xFF0000) >> 16) / 255.0,
                    green: CGFloat((hexValue & 0x00FF00) >> 8) / 255.0,
                    blue: CGFloat(hexValue & 0x0000FF) / 255.0,
                    alpha: 1.0)
        case 8:
            return (red: CGFloat((hexValue & 0xFF00_0000) >> 24) / 255.0,
                    green: CGFloat((hexValue & 0x00FF_0000) >> 16) / 255.0,
                    blue: CGFloat((hexValue & 0x0000_FF00) >> 8) / 255.0,
                    alpha: CGFloat(hexValue & 0x0000_00FF) / 255.0)
        default:
            return nil
        }
    }

    func hexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    func getRGBA() -> [Double] {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)

        return [Double(r), Double(g), Double(b), Double(a)]
    }

    static func calculateColor(orgColor: UIColor, overlayColor: UIColor) -> UIColor {
        // Helper function to clamp values to range (0.0 ... 1.0)
        func clampValue(_ v: CGFloat) -> CGFloat {
            guard v > 0 else { return 0 }
            guard v < 1 else { return 1 }
            return v
        }

        var (r1, g1, b1, a1) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        var (r2, g2, b2, a2) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))

        orgColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        overlayColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        // Make sure the input colors are well behaved
        // Components should be in the range (0.0 ... 1.0)
        r1 = clampValue(r1)
        g1 = clampValue(g1)
        b1 = clampValue(b1)

        r2 = clampValue(r2)
        g2 = clampValue(g2)
        b2 = clampValue(b2)
        a2 = clampValue(a2)

        let color = UIColor(red: r1 * (1 - a2) + r2 * a2,
                            green: g1 * (1 - a2) + g2 * a2,
                            blue: b1 * (1 - a2) + b2 * a2,
                            alpha: 1)

        return color
    }
}
