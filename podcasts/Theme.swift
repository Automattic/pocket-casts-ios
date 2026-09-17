import Foundation
import PocketCastsServer
import PocketCastsUtils
import Combine
import os

extension ThemeType: AnalyticsDescribable {
    static var displayOrder: [ThemeType] {
        [.light, .dark, .rosé, .extraDark, .indigo, .contrastDark, .contrastLight, .electric, .classic]
    }

    var isDark: Bool {
        switch self {
        case .dark, .extraDark, .electric, .contrastDark:
            return true
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return false
        }
    }

    var isPlusOnly: Bool {
        switch self {
        case .electric, .classic:
            return true
        default:
            return false
        }
    }

    var description: String {
        switch self {
        case .light:
            return L10n.themeLight
        case .dark:
            return L10n.themeDark
        case .extraDark:
            return L10n.themeExtraDark
        case .electric:
            return L10n.themeElectricity
        case .classic:
            return L10n.themeClassic
        case .indigo:
            return L10n.themeIndigo
        case .rosé:
            return L10n.themeRose
        case .contrastLight:
            return L10n.themeLightContrast
        case .contrastDark:
            return L10n.themeDarkContrast
        }
    }

    var icon: UIImage? {
        UIImage(named: imageName)
    }

    var imageName: String {
        switch self {
        case .light:
            return"lightThemeAbstract"
        case .dark:
            return "darkThemeAbstract"
        case .extraDark:
            return "extraDarkThemeAbstract"
        case .electric:
            return "electricityThemeAbstract"
        case .classic:
            return "classicThemeAbstract"
        case .indigo:
            return "indigoThemeAbstract"
        case .rosé:
            return "roseThemeAbstract"
        case .contrastLight:
            return "contrastLightThemeAbstract"
        case .contrastDark:
            return "contrastDarkThemeAbstract"
        }
    }

    var analyticsDescription: String {
        switch self {
        case .light:
            return"default_light"
        case .dark:
            return "default_dark"
        case .extraDark:
            return "extra_dark"
        case .electric:
            return "electric"
        case .classic:
            return "classic"
        case .indigo:
            return "indigo"
        case .rosé:
            return "rose"
        case .contrastLight:
            return "light_contrast"
        case .contrastDark:
            return "dark_contrast"
        }
    }
}

@MainActor
class Theme: ObservableObject {
    nonisolated static let themeKey = "theme"
    nonisolated static let preferredDarkThemeKey = "preferredDarkTheme"
    nonisolated static let preferredLightThemeKey = "preferredLightTheme"
    nonisolated static let sharedTheme = Theme()

    typealias ThemeType = PocketCastsServer.ThemeType

    nonisolated private static let activeThemeTypeLock = OSAllocatedUnfairLock(initialState: savedTheme())

    nonisolated static var activeThemeType: ThemeType {
        activeThemeTypeLock.withLock { $0 }
    }

    @Published var activeTheme: ThemeType = Theme.savedTheme() {
        willSet {
            // There's a SwiftUI bug (last checked in SwiftUI 3, iOS 15.4) where if this variable changes while the app is backgrounded, the events aren't correctly sent so here we manually fire a will change if our app isn't active
            // before removing this, test for the bug in this issue: https://github.com/shiftyjelly/pocketcasts-ios/issues/3969
            if UIApplication.shared.applicationState != .active {
                objectWillChange.send()
            }
        }
        didSet {
            Theme.activeThemeTypeLock.withLock { [activeTheme] in $0 = activeTheme }
            UserDefaults.standard.set(activeTheme.old.rawValue, forKey: Theme.themeKey)

            // if the user is changing from or to the radioactive theme, we need to clear our memory cache because processing is applied to these images
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastImageReCacheRequired)

            NotificationCenter.postOnMainThread(notification: Constants.Notifications.themeChanged)
        }
    }

    nonisolated init() {
        NotificationCenter.default.addObserver(self, selector: #selector(systemThemeDidChange(_:)), name: Constants.Notifications.systemThemeMayHaveChanged, object: nil)
    }

    init(previewTheme: ThemeType) {
        activeTheme = previewTheme
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    nonisolated private static func savedTheme() -> ThemeType {
        let savedTheme = UserDefaults.standard.integer(forKey: Theme.themeKey)
        if savedTheme == 0 && UserDefaults.standard.object(forKey: Constants.UserDefaults.shouldFollowSystemThemeKey) == nil {
            Settings.setShouldFollowSystemTheme(true)
        }
        return ThemeType(old: ThemeType.Old(rawValue: savedTheme) ?? .light)
    }

    @objc private func systemThemeDidChange(_ notification: Notification) {
        if Settings.shouldFollowSystemTheme() {
            toggleTheme()
        }
    }

    nonisolated class func isDarkTheme() -> Bool {
        Theme.activeThemeType.isDark
    }

    nonisolated class func preferredDarkTheme() -> ThemeType {
        let savedType = UserDefaults.standard.integer(forKey: preferredDarkThemeKey)

        guard let oldTheme = ThemeType.Old(rawValue: savedType) else { return .dark }

        let themeType = ThemeType(old: oldTheme)

        return themeType
    }

    class func setPreferredDarkTheme(_ preferredType: ThemeType, systemIsDark: Bool, userInitiated: Bool = false) {
        UserDefaults.standard.setValue(preferredType.old.rawValue, forKey: preferredDarkThemeKey)

        // change the active theme if it needs to change
        if Settings.shouldFollowSystemTheme(), systemIsDark {
            Theme.sharedTheme.activeTheme = preferredType
        }

        guard userInitiated else { return }
        Settings.trackValueChanged(.settingsAppearanceDarkThemeChanged, value: preferredType)
    }

    nonisolated class func preferredLightTheme() -> ThemeType {
        let savedType = UserDefaults.standard.integer(forKey: preferredLightThemeKey)

        guard let oldTheme = ThemeType.Old(rawValue: savedType) else { return .light }

        let themeType = ThemeType(old: oldTheme)

        return themeType
    }

    class func setPreferredLightTheme(_ preferredType: ThemeType, systemIsDark: Bool) {
        UserDefaults.standard.setValue(preferredType.old.rawValue, forKey: preferredLightThemeKey)

        // change the active theme if it needs to change
        if Settings.shouldFollowSystemTheme() {
            if !systemIsDark {
                Theme.sharedTheme.activeTheme = preferredType
            }
            Settings.trackValueChanged(.settingsAppearanceLightThemeChanged, value: preferredType)
        } else {
            Theme.sharedTheme.activeTheme = preferredType
            Settings.trackValueChanged(.settingsAppearanceThemeChanged, value: preferredType)
        }
    }

    func toggleTheme() {
        let newTheme = toggledThemed()
        if activeTheme != newTheme {
            activeTheme = toggledThemed()
        }
    }

    private func toggledThemed() -> ThemeType {
        guard Settings.shouldFollowSystemTheme() else {
            return Theme.preferredLightTheme()
        }

        return Theme.systemIsDark ? Theme.preferredDarkTheme() : Theme.preferredLightTheme()
    }
}
