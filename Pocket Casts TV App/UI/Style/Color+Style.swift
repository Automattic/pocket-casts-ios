import SwiftUI
import UIKit
import PocketCastsUtils

// Values come from the tvOS design tokens (Figma "Light mode" / "Dark mode" sets).
// Each token resolves dynamically on the active user interface style; see `appearance(light:dark:)`.

extension Color {

    static let pcTextPrimary = Color(uiColor: .pcTextPrimary)

    // The "-active" tokens style content shown *on* the focused surface, which inverts relative to
    // the page: the focused surface is near-white in dark mode (so active text is dark) and near-black
    // in light mode (so active text is light). See `pcBackgroundActive`.
    static let pcTextPrimaryActive = Color(uiColor: .appearance(light: "#FBFBFC", dark: "#161718"))

    static let pcTextSecondary = Color(uiColor: .appearance(light: "#5A5D62", dark: "#B0B3B8"))

    static let pcTextSecondaryActive = Color(uiColor: .appearance(light: "#C8CACE", dark: "#3D4044"))

    static let pcTextTertiary = Color(uiColor: .appearance(light: "#909398", dark: "#7A7D82"))

    static let pcTextTertiaryActive = Color(uiColor: .appearance(light: "#909398", dark: "#7A7D82"))

    static let pcTextDisabled = Color(uiColor: .appearance(light: "#C0C2C6", dark: "#4A4D51"))

    static let pcTextDisabledActive = Color(uiColor: .appearance(light: "#5A5D62", dark: "#B0B3B8"))

    // Text drawn over artwork or fixed-color cards (e.g. playlist colors), which stay dark in
    // both appearances. These never flip, so the text stays readable on those surfaces.
    static let pcTextOnColorPrimary = Color(uiColor: UIColor(hex: "#FBFBFC"))

    static let pcTextOnColorSecondary = Color(uiColor: UIColor(hex: "#B0B3B8"))

    static let pcBackgroundSunken = Color(uiColor: .appearance(light: "#E8E9EA", dark: "#161718"))

    static let pcBackgroundSurface = Color(uiColor: .appearance(light: "#F0F1F2", dark: "#1F2123"))

    // Top/bottom stops of the page gradient applied in `RootView`. The top is a touch
    // lighter than `pcBackgroundSurface` (to mimic light hitting the screen from above)
    // and the bottom a touch darker, so focused-card shadows have something to read against.
    static let pcBackgroundTop = Color(uiColor: .appearance(light: "#FFFFFF", dark: "#2B2E32"))

    static let pcBackgroundBottom = Color(uiColor: .appearance(light: "#E6E7E9", dark: "#171819"))

    static let pcBackgroundBase = Color(uiColor: .appearance(light: "#F7F7F8", dark: "#292B2E"))

    static let pcBackgroundOverlay = Color(uiColor: .pcBackgroundOverlay)

    // Focus highlight (`bg-active`). The focused surface inverts against the page but stays a
    // step back from pure black/white — a silvery card in dark mode, a charcoal card in light —
    // so the sheen and shadow on focused cards do the lifting instead of raw brightness.
    static let pcBackgroundActive = Color(uiColor: .appearance(light: "#2A2D31", dark: "#D4D6DB"))

    // `bg-active-20` token: the active color at 20% opacity. Alpha is applied inside each branch so
    // the color still re-resolves between light and dark (calling `withAlphaComponent` on a dynamic
    // color would flatten it to a single appearance).
    static let pcBackgroundActive20 = Color(uiColor: .appearance(
        light: UIColor(hex: "#161718").withAlphaComponent(0.2),
        dark: UIColor(hex: "#FBFBFC").withAlphaComponent(0.2)
    ))

    // Shadows stay black but are much softer in light mode, where a heavy drop shadow looks harsh.
    static let pcShadowLight = Color(uiColor: .appearance(light: .black.withAlphaComponent(0.1), dark: .black.withAlphaComponent(0.2)))

    static let pcShadowStrong = Color(uiColor: .appearance(light: .black.withAlphaComponent(0.18), dark: .black.withAlphaComponent(0.6)))

    // Soft lift under a focused card. Only present in light mode — in dark mode the focus already
    // pops as a bright card on a dark background, so no shadow is needed (and it would just darken
    // the dark page).
    static let pcShadowFocus = Color(uiColor: .appearance(light: .black.withAlphaComponent(0.18), dark: .clear))
}

extension UIColor {

    // Tokens also consumed from UIKit (e.g. `ToastView`) are defined here as genuine
    // dynamic `UIColor`s so they re-resolve with the view's traits. The `Color`
    // counterparts above wrap these, keeping a single source of truth.

    static let pcTextPrimary = appearance(light: "#161718", dark: "#FBFBFC")

    static let pcBackgroundOverlay = appearance(light: "#FFFFFF", dark: "#323538")

    /// Resolves to `light` in light mode, otherwise `dark`.
    /// An unspecified user interface style falls back to `dark`, preserving the original behavior.
    fileprivate static func appearance(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .light ? light : dark }
    }

    fileprivate static func appearance(light: String, dark: String) -> UIColor {
        appearance(light: UIColor(hex: light), dark: UIColor(hex: dark))
    }
}
