import SwiftUI

extension Color {
    /// A convenience initializer that takes RGB values 0-255 and converts to the 0-1 range expected by Color.
    /// - Parameters:
    ///   - red: A value 0-255 for the red component
    ///   - green: A value 0-255 for the green component
    ///   - blue: A value 0-255 for the blue component
    public init(red: Int, green: Int, blue: Int) {
        let rgbMax = 255.0
        self.init(.sRGB, red: Double(red)/rgbMax, green: Double(green)/rgbMax, blue: Double(blue)/rgbMax)
    }
}
