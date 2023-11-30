import Foundation
import SwiftUI

let darkBackgroundColor = Color(UIColor.tertiarySystemFill)
let lightBackgroundColor = Color(.clear)
let rgbMax = 255.0
let newTopBackgroundColor = Color(.sRGB, red: 244/rgbMax, green: 62/rgbMax, blue: 55/rgbMax)
let newBottomBackgroundColor = Color(.sRGB, red: 217/rgbMax, green: 32/rgbMax, blue: 28/rgbMax)

struct LightBackgroundShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 0.08), radius: 50, x: 0, y: 40)
    }
}

extension View {
    func lightBackgroundShadow() -> some View {
        modifier(LightBackgroundShadow())
    }
}
