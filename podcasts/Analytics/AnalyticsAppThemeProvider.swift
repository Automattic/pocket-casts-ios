import Foundation

protocol AnalyticsAppThemeProviding {
    var appThemeProperties: [String: Any] { get }
}

struct AnalyticsAppThemeProvider: AnalyticsAppThemeProviding {
    var appThemeProperties: [String: Any] {
        return [
            "theme_selected": Theme.sharedTheme.activeTheme.analyticsDescription,
            "theme_dark_preference": Theme.preferredDarkTheme().analyticsDescription,
            "theme_light_preference": Theme.preferredLightTheme().analyticsDescription,
            "theme_use_system_settings": Settings.shouldFollowSystemTheme()
            ]
    }
}
