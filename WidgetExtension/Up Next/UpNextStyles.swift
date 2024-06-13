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

    static let bold = PCWidgetColorScheme(
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

    static let contrast = PCWidgetColorScheme(
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

    static let contrastDark = PCWidgetColorScheme(
        topBackgroundColor: widgetCoolGrey,
        bottomBackgroundColor: widgetBlack,
        topButtonBackgroundColor: .white,
        bottomButtonBackgroundColor: widgetCoolGrey,
        topTextColor: .white,
        bottomTextColor: .white,
        topButtonTextColor: widgetCoolGrey,
        bottomButtonTextColor: .white,
        iconAssetName: "logo_red_small",
        filterViewBackgroundColor: widgetBlack,
        filterViewTextColor: .white,
        filterViewIconAssetName: "logo_red_small"
    )

    static let contrastNowPlaying = PCWidgetColorScheme(
        topBackgroundColor: PCWidgetColorScheme.contrast.topBackgroundColor,
        bottomBackgroundColor: PCWidgetColorScheme.contrast.bottomBackgroundColor,
        topButtonBackgroundColor: PCWidgetColorScheme.contrast.bottomButtonBackgroundColor,
        bottomButtonBackgroundColor: PCWidgetColorScheme.contrast.bottomButtonBackgroundColor,
        topTextColor: PCWidgetColorScheme.contrast.topTextColor,
        bottomTextColor: PCWidgetColorScheme.contrast.bottomTextColor,
        topButtonTextColor: PCWidgetColorScheme.contrast.bottomButtonTextColor,
        bottomButtonTextColor: PCWidgetColorScheme.contrast.bottomButtonTextColor,
        iconAssetName: "logo_red_small",
        filterViewBackgroundColor: .white, // not used in now playing
        filterViewTextColor: .white, // not used in now playing,
        filterViewIconAssetName: "logo_red_small" // not used in now playing
    )

    static let contrastNowPlayingDark = PCWidgetColorScheme(
        topBackgroundColor: PCWidgetColorScheme.contrastDark.topBackgroundColor,
        bottomBackgroundColor: PCWidgetColorScheme.contrastDark.bottomBackgroundColor,
        topButtonBackgroundColor: PCWidgetColorScheme.contrastDark.bottomButtonBackgroundColor,
        bottomButtonBackgroundColor: PCWidgetColorScheme.contrastDark.bottomButtonBackgroundColor,
        topTextColor: PCWidgetColorScheme.contrastDark.topTextColor,
        bottomTextColor: PCWidgetColorScheme.contrastDark.bottomTextColor,
        topButtonTextColor: PCWidgetColorScheme.contrastDark.bottomButtonTextColor,
        bottomButtonTextColor: PCWidgetColorScheme.contrastDark.bottomButtonTextColor,
        iconAssetName: "logo_red_small",
        filterViewBackgroundColor: PCWidgetColorScheme.contrastDark.filterViewBackgroundColor, // not used in now playing
        filterViewTextColor: PCWidgetColorScheme.contrastDark.filterViewTextColor, // not used in now playing,
        filterViewIconAssetName: "logo_red_small" // not used in now playing
    )

    static let boldNowPlaying = PCWidgetColorScheme(
        topBackgroundColor: PCWidgetColorScheme.bold.topBackgroundColor,
        bottomBackgroundColor: PCWidgetColorScheme.bold.topBackgroundColor,
        topButtonBackgroundColor: PCWidgetColorScheme.bold.topButtonBackgroundColor,
        bottomButtonBackgroundColor: PCWidgetColorScheme.bold.bottomButtonBackgroundColor,
        topTextColor: PCWidgetColorScheme.bold.topTextColor,
        bottomTextColor: PCWidgetColorScheme.bold.topTextColor,
        topButtonTextColor: PCWidgetColorScheme.bold.topButtonTextColor,
        bottomButtonTextColor: PCWidgetColorScheme.bold.bottomButtonTextColor,
        iconAssetName: "logo_white_small_transparent",
        filterViewBackgroundColor: .white, // not used in now playing
        filterViewTextColor: .white, // not used in now playing
        filterViewIconAssetName: "logo_red_small" // not used in now playing
    )
}

let rgbMax = 255.0
let widgetRedDark = Color(.sRGB, red: 217/rgbMax, green: 32/rgbMax, blue: 28/rgbMax)
let widgetRedLight = Color(.sRGB, red: 244/rgbMax, green: 62/rgbMax, blue: 55/rgbMax)
let widgetBlack = Color(.sRGB, red: 22/rgbMax, green: 23/rgbMax, blue: 24/rgbMax)
let widgetCoolGrey = Color(.sRGB, red: 41/rgbMax, green: 43/rgbMax, blue: 46/rgbMax)

struct WidgetColorScheme: EnvironmentKey {
    static var defaultValue: PCWidgetColorScheme = .bold
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
