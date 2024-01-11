import Foundation
import SwiftUI

let darkBackgroundColor = Color(UIColor.tertiarySystemFill)
let lightBackgroundColor = Color(.clear)

struct PCWidgetColorScheme {
    let topBackgroundColor: Color
    let bottomBackgroundColor: Color
    let topButtonBackgroundColor: Color
    let bottomButtonBackgroundColor: Color
    let topTextColor: Color
    let bottomTextColor: Color
    let topButtonTextColor: Color // foreground color?
    let bottomButtonTextColor: Color // foreground color?
}

let rgbMax = 255.0
let widgetRedDark = Color(.sRGB, red: 217/rgbMax, green: 32/rgbMax, blue: 28/rgbMax)
let widgetRedLight = Color(.sRGB, red: 244/rgbMax, green: 62/rgbMax, blue: 55/rgbMax)
let widgetBlack = Color(.sRGB, red: 22/rgbMax, green: 23/rgbMax, blue: 24/rgbMax)

let widgetColorSchemeBold = PCWidgetColorScheme(
    topBackgroundColor: widgetRedLight,
    bottomBackgroundColor: widgetRedDark,
    topButtonBackgroundColor: .white,
    bottomButtonBackgroundColor: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.2),
    topTextColor: .white,
    bottomTextColor: .white,
    topButtonTextColor: widgetRedLight,
    bottomButtonTextColor: .white
)

let widgetColorSchemeContrast = PCWidgetColorScheme(
    topBackgroundColor: widgetRedDark,
    bottomBackgroundColor: .white,
    topButtonBackgroundColor: .white,
    bottomButtonBackgroundColor: widgetRedDark,
    topTextColor: .white,
    bottomTextColor: widgetBlack,
    topButtonTextColor: widgetRedDark,
    bottomButtonTextColor: .white
)

let widgetColorSchemeContrastNowPlaying = PCWidgetColorScheme(
    topBackgroundColor: widgetColorSchemeContrast.topBackgroundColor,
    bottomBackgroundColor: widgetColorSchemeContrast.bottomBackgroundColor,
    topButtonBackgroundColor: widgetColorSchemeContrast.bottomButtonBackgroundColor,
    bottomButtonBackgroundColor: widgetColorSchemeContrast.bottomButtonBackgroundColor,
    topTextColor: widgetColorSchemeContrast.topTextColor,
    bottomTextColor: widgetColorSchemeContrast.bottomTextColor,
    topButtonTextColor: widgetColorSchemeContrast.bottomButtonTextColor,
    bottomButtonTextColor: widgetColorSchemeContrast.bottomButtonTextColor
)

let widgetColorSchemeBoldNowPlaying = PCWidgetColorScheme(
    topBackgroundColor: widgetColorSchemeBold.topBackgroundColor,
    bottomBackgroundColor: widgetColorSchemeBold.topBackgroundColor,
    topButtonBackgroundColor: widgetColorSchemeBold.topButtonBackgroundColor,
    bottomButtonBackgroundColor: widgetColorSchemeBold.bottomButtonBackgroundColor,
    topTextColor: widgetColorSchemeBold.topTextColor,
    bottomTextColor: widgetColorSchemeBold.topTextColor,
    topButtonTextColor: widgetColorSchemeBold.topButtonTextColor,
    bottomButtonTextColor: widgetColorSchemeBold.bottomButtonTextColor
)

struct WidgetColorScheme: EnvironmentKey {
    static var defaultValue: PCWidgetColorScheme = widgetColorSchemeBold
}

extension EnvironmentValues {
    var widgetColorScheme: PCWidgetColorScheme {
        get { self[WidgetColorScheme.self] }
        set { self[WidgetColorScheme.self] = newValue }
    }
}

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
