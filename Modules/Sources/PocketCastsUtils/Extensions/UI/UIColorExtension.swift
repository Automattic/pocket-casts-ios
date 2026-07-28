
import UIKit

public extension UIColor {
    convenience init(hex: String) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0

        if hex.hasPrefix("#") {
            let index = hex.index(hex.startIndex, offsetBy: 1)
            let hexString = String(hex[index...])
            let scanner = Scanner(string: hexString)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexInt64(&hexValue) {
                switch hexString.count {
                case 3:
                    red = CGFloat((hexValue & 0xF00) >> 8) / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4) / 15.0
                    blue = CGFloat(hexValue & 0x00F) / 15.0
                case 4:
                    red = CGFloat((hexValue & 0xF000) >> 12) / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8) / 15.0
                    blue = CGFloat((hexValue & 0x00F0) >> 4) / 15.0
                    alpha = CGFloat(hexValue & 0x000F) / 15.0
                case 6:
                    red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
                    blue = CGFloat(hexValue & 0x0000FF) / 255.0
                case 8:
                    red = CGFloat((hexValue & 0xFF00_0000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF_0000) >> 16) / 255.0
                    blue = CGFloat((hexValue & 0x0000_FF00) >> 8) / 255.0
                    alpha = CGFloat(hexValue & 0x0000_00FF) / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
                }
            } else {
                print("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix")
        }
        self.init(red: red, green: green, blue: blue, alpha: alpha)
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
