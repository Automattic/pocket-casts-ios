import Foundation

struct AnalyticsAppThemeProvider: AnalyticsAppThemeProviding {
    var appThemeProperties: [String: Sendable] {
        return [
            "theme_selected": Theme.shared.activeTheme.analyticsDescription,
            "theme_dark_preference": Theme.preferredDarkTheme().analyticsDescription,
            "theme_light_preference": Theme.preferredLightTheme().analyticsDescription,
            "theme_use_system_settings": Settings.shouldFollowSystemTheme
        ]
    }
}
