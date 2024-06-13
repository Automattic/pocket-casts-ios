import SwiftUI

let widgetRedDark = Color(red: 217, green: 32, blue: 28)
let widgetRedLight = Color(red: 244, green: 62, blue: 55)
let widgetBlack = Color(red: 22, green: 23, blue: 24)
let widgetCoolGrey = Color(red: 41, green: 43, blue: 46)

struct PCWidgetColorScheme {
    let topBackgroundColor: Color
    let bottomBackgroundColor: Color
    let topButtonBackgroundColor: Color
    let bottomButtonBackgroundColor: Color
    let topTextColor: Color
    let bottomTextColor: Color
    let topButtonTextColor: Color
    let bottomButtonTextColor: Color
    let iconAssetName: String
    let filterViewBackgroundColor: Color
    let filterViewTextColor: Color
    let filterViewIconAssetName: String

    static let bold = PCWidgetColorScheme(
        topBackgroundColor: widgetRedLight,
        bottomBackgroundColor: widgetRedDark,
        topButtonBackgroundColor: .white,
        bottomButtonBackgroundColor: .white.opacity(0.2),
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

struct WidgetColorScheme: EnvironmentKey {
    static var defaultValue: PCWidgetColorScheme = .bold
}

extension EnvironmentValues {
    var widgetColorScheme: PCWidgetColorScheme {
        get { self[WidgetColorScheme.self] }
        set { self[WidgetColorScheme.self] = newValue }
    }
}
