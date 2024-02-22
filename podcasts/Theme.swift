import Foundation
import PocketCastsServer
import PocketCastsUtils

extension ThemeType: AnalyticsDescribable {
    static var displayOrder: [ThemeType] {
        [.light, .dark, .rosé, .extraDark, .indigo, .contrastDark, .contrastLight, .electric, .classic, .radioactive]
    }

    var isDark: Bool {
        switch self {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return true
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return false
        }
    }

    var isPlusOnly: Bool {
        switch self {
        case .electric, .classic, .radioactive:
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
        case .radioactive:
            return L10n.themeRadioactivity
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
        case .radioactive:
            return "radioactiveThemeAbstract"
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
        case .radioactive:
            return "radioactive"
        case .rosé:
            return "rose"
        case .contrastLight:
            return "light_contrast"
        case .contrastDark:
            return "dark_contrast"
        }
    }
}

class Theme: ObservableObject {
    static let themeKey = "theme"
    static let preferredDarkThemeKey = "preferredDarkTheme"
    static let preferredLightThemeKey = "preferredLightTheme"
    static let sharedTheme = Theme()

    typealias ThemeType = PocketCastsServer.ThemeType

    @Published var activeTheme: ThemeType {
        willSet {
            // There's a SwiftUI bug (last checked in SwiftUI 3, iOS 15.4) where if this variable changes while the app is backgrounded, the events aren't correctly sent so here we manually fire a will change if our app isn't active
            // before removing this, test for the bug in this issue: https://github.com/shiftyjelly/pocketcasts-ios/issues/3969
            if UIApplication.shared.applicationState != .active {
                objectWillChange.send()
            }
        }
        didSet {
            if FeatureFlag.settingsSync.enabled {
                SettingsStore.appSettings.theme = activeTheme
            }
            UserDefaults.standard.set(activeTheme.rawValue, forKey: Theme.themeKey)

            // if the user is changing from or to the radioactive theme, we need to clear our memory cache because processing is applied to these images
            if oldValue == .radioactive || activeTheme == .radioactive {
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastImageReCacheRequired)
            }

            NotificationCenter.postOnMainThread(notification: Constants.Notifications.themeChanged)
        }
    }

    init() {
        if FeatureFlag.settingsSync.enabled {
            activeTheme = SettingsStore.appSettings.theme
        } else {
            let savedTheme = UserDefaults.standard.integer(forKey: Theme.themeKey)
            if savedTheme == 0 && UserDefaults.standard.object(forKey: Constants.UserDefaults.shouldFollowSystemThemeKey) == nil {
                Settings.setShouldFollowSystemTheme(true)
            }
            activeTheme = ThemeType(rawValue: Int32(savedTheme)) ?? .light
        }

        NotificationCenter.default.addObserver(self, selector: #selector(systemThemeDidChange(_:)), name: Constants.Notifications.systemThemeMayHaveChanged, object: nil)
    }

    init(previewTheme: ThemeType) {
        activeTheme = previewTheme
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func systemThemeDidChange(_ notification: Notification) {
        if Settings.shouldFollowSystemTheme() {
            toggleTheme()
        }
    }

    class func isDarkTheme() -> Bool {
        Theme.sharedTheme.activeTheme.isDark
    }

    class func preferredDarkTheme() -> ThemeType {
        if FeatureFlag.settingsSync.enabled {
            return SettingsStore.appSettings.darkThemePreference
        }

        let savedType = UserDefaults.standard.integer(forKey: preferredDarkThemeKey)

        guard let oldTheme = ThemeType.Old(rawValue: savedType) else { return .dark }

        let themeType = ThemeType(old: oldTheme)

        return themeType
    }

    class func setPreferredDarkTheme(_ preferredType: ThemeType, systemIsDark: Bool, userInitiated: Bool = false) {

        if FeatureFlag.settingsSync.enabled {
            SettingsStore.appSettings.darkThemePreference = preferredType
        }
        UserDefaults.standard.setValue(preferredType.old.rawValue, forKey: preferredDarkThemeKey)

        // change the active theme if it needs to change
        if Settings.shouldFollowSystemTheme(), systemIsDark {
            Theme.sharedTheme.activeTheme = preferredType
        }

        guard userInitiated else { return }
        Settings.trackValueChanged(.settingsAppearanceDarkThemeChanged, value: preferredType)
    }

    class func preferredLightTheme() -> ThemeType {

        if FeatureFlag.settingsSync.enabled {
            return SettingsStore.appSettings.lightThemePreference
        }

        let savedType = UserDefaults.standard.integer(forKey: preferredLightThemeKey)

        guard let oldTheme = ThemeType.Old(rawValue: savedType) else { return .dark }

        let themeType = ThemeType(old: oldTheme)

        return themeType
    }

    class func setPreferredLightTheme(_ preferredType: ThemeType, systemIsDark: Bool) {

        if FeatureFlag.settingsSync.enabled {
            SettingsStore.appSettings.lightThemePreference = preferredType
        }
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

    func toggleDarkLightThemeAnimated(topLevelView: UIView, originView: UIView) {
        let themeToChangeTo = toggledThemed()

        changeThemeAnimated(themeToChangeTo, topLevelView: topLevelView, originView: originView)
    }

    func cycleThemeForTesting() {
        activeTheme = ThemeType(rawValue: activeTheme.rawValue + 1) ?? ThemeType.light
    }

    private func toggledThemed() -> ThemeType {
        guard Settings.shouldFollowSystemTheme() else {
            return Theme.preferredLightTheme()
        }

        return UITraitCollection.current.userInterfaceStyle == .dark ? Theme.preferredDarkTheme() : Theme.preferredLightTheme()
    }

    func changeThemeAnimated(_ theme: ThemeType, topLevelView: UIView, originView: UIView) {
        // take a before and after picture
        let currentThemeSnapshot = topLevelView.sj_snapshot()
        activeTheme = theme
        let newThemeSnapshot = topLevelView.sj_snapshot(afterScreenUpdate: true)

        // put before at the bottom, after on top of it
        topLevelView.addSubview(currentThemeSnapshot)
        topLevelView.addSubview(newThemeSnapshot)
        currentThemeSnapshot.anchorToAllSidesOf(view: topLevelView)
        newThemeSnapshot.anchorToAllSidesOf(view: topLevelView)

        // create a path where a circle will grow out from the logo
        let originViewFrame = newThemeSnapshot.convert(originView.frame, from: originView.superview)
        let smallCirclePath = animationCircleOfSize(originView.bounds.size.height, originViewFrame: originViewFrame)
        let largeCirclePath = animationCircleOfSize(topLevelView.bounds.width * 4, originViewFrame: originViewFrame)

        let mask = CAShapeLayer()
        mask.path = smallCirclePath.cgPath
        mask.backgroundColor = UIColor.black.cgColor
        newThemeSnapshot.layer.mask = mask

        // run the animation, being a circular reveal of the new theme, on completion remove our snapshot views
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            currentThemeSnapshot.removeFromSuperview()
            newThemeSnapshot.removeFromSuperview()
        }

        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.toValue = largeCirclePath.cgPath
        pathAnimation.duration = 0.4
        pathAnimation.fillMode = CAMediaTimingFillMode.forwards
        pathAnimation.isRemovedOnCompletion = false
        pathAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        mask.add(pathAnimation, forKey: "path")
        CATransaction.commit()
    }

    private func animationCircleOfSize(_ size: CGFloat, originViewFrame: CGRect) -> UIBezierPath {
        let yOffset = (size / 2.0) - (originViewFrame.height / 2.0)
        let xOffset = (size / 2.0) - (originViewFrame.width / 2.0)
        let circleRect = CGRect(x: originViewFrame.origin.x - xOffset, y: originViewFrame.origin.y - yOffset, width: size, height: size)

        return UIBezierPath(roundedRect: circleRect, cornerRadius: size / 2.0)
    }
}
