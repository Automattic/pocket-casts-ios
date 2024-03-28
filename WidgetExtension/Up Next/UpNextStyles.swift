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
    let iconAssetName: String
    let filterViewBackgroundColor: Color
    let filterViewTextColor: Color
    let filterViewIconAssetName: String
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
    bottomButtonTextColor: .white,
    iconAssetName: "logo_white_small_transparent",
    filterViewBackgroundColor: widgetRedLight,
    filterViewTextColor: .white,
    filterViewIconAssetName: "logo_white_small_transparent"
)

let widgetColorSchemeContrast = PCWidgetColorScheme(
    topBackgroundColor: widgetRedDark,
    bottomBackgroundColor: .white,
    topButtonBackgroundColor: .white,
    bottomButtonBackgroundColor: widgetRedDark,
    topTextColor: .white,
    bottomTextColor: widgetBlack,
    topButtonTextColor: widgetRedDark,
    bottomButtonTextColor: .white,
    iconAssetName: "logo_white_small_transparent",
    filterViewBackgroundColor: .white,
    filterViewTextColor: widgetBlack,
    filterViewIconAssetName: "logo_red_small"
)

let widgetColorSchemeContrastDark = PCWidgetColorScheme(
    topBackgroundColor: widgetRedDark,
    bottomBackgroundColor: widgetBlack,
    topButtonBackgroundColor: .white,
    bottomButtonBackgroundColor: widgetRedDark,
    topTextColor: .white,
    bottomTextColor: .white,
    topButtonTextColor: widgetRedDark,
    bottomButtonTextColor: widgetBlack,
    iconAssetName: "logo_white_small_transparent",
    filterViewBackgroundColor: widgetBlack,
    filterViewTextColor: .white,
    filterViewIconAssetName: "logo_red_small"
)

let widgetColorSchemeContrastNowPlaying = PCWidgetColorScheme(
    topBackgroundColor: widgetColorSchemeContrast.topBackgroundColor,
    bottomBackgroundColor: widgetColorSchemeContrast.bottomBackgroundColor,
    topButtonBackgroundColor: widgetColorSchemeContrast.bottomButtonBackgroundColor,
    bottomButtonBackgroundColor: widgetColorSchemeContrast.bottomButtonBackgroundColor,
    topTextColor: widgetColorSchemeContrast.topTextColor,
    bottomTextColor: widgetColorSchemeContrast.bottomTextColor,
    topButtonTextColor: widgetColorSchemeContrast.bottomButtonTextColor,
    bottomButtonTextColor: widgetColorSchemeContrast.bottomButtonTextColor,
    iconAssetName: "logo_red_small",
    filterViewBackgroundColor: .white, // not used in now playing
    filterViewTextColor: .white, // not used in now playing,
    filterViewIconAssetName: "logo_red_small" // not used in now playing
)

let widgetColorSchemeContrastNowPlayingDark = PCWidgetColorScheme(
    topBackgroundColor: widgetColorSchemeContrastDark.topBackgroundColor,
    bottomBackgroundColor: widgetColorSchemeContrastDark.bottomBackgroundColor,
    topButtonBackgroundColor: widgetColorSchemeContrastDark.bottomButtonBackgroundColor,
    bottomButtonBackgroundColor: widgetColorSchemeContrastDark.bottomButtonBackgroundColor,
    topTextColor: widgetColorSchemeContrastDark.topTextColor,
    bottomTextColor: widgetColorSchemeContrastDark.bottomTextColor,
    topButtonTextColor: widgetColorSchemeContrastDark.bottomButtonTextColor,
    bottomButtonTextColor: widgetColorSchemeContrastDark.bottomButtonTextColor,
    iconAssetName: "logo_red_small",
    filterViewBackgroundColor: widgetColorSchemeContrastDark.filterViewBackgroundColor, // not used in now playing
    filterViewTextColor: widgetColorSchemeContrastDark.filterViewTextColor, // not used in now playing,
    filterViewIconAssetName: "logo_red_small" // not used in now playing
)

let widgetColorSchemeBoldNowPlaying = PCWidgetColorScheme(
    topBackgroundColor: widgetColorSchemeBold.topBackgroundColor,
    bottomBackgroundColor: widgetColorSchemeBold.topBackgroundColor,
    topButtonBackgroundColor: widgetColorSchemeBold.topButtonBackgroundColor,
    bottomButtonBackgroundColor: widgetColorSchemeBold.bottomButtonBackgroundColor,
    topTextColor: widgetColorSchemeBold.topTextColor,
    bottomTextColor: widgetColorSchemeBold.topTextColor,
    topButtonTextColor: widgetColorSchemeBold.topButtonTextColor,
    bottomButtonTextColor: widgetColorSchemeBold.bottomButtonTextColor,
    iconAssetName: "logo_white_small_transparent",
    filterViewBackgroundColor: .white, // not used in now playing
    filterViewTextColor: .white, // not used in now playing
    filterViewIconAssetName: "logo_red_small" // not used in now playing
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
