import JLRoutes
import UIKit
import PocketCastsUtils

class SceneDelegate: UIResponder, UISceneDelegate, UIWindowSceneDelegate {
    var window: UIWindow?
    private var systemAppearanceObservation: Any?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.rootViewController = MainTabBarController()

        // Capture the system style before applying any window-level override so the
        // initial value reflects the actual system, not our override.
        Theme.systemIsDark = (windowScene.traitCollection.userInterfaceStyle == .dark)
        window.applyInterfaceStyleForActiveTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)

        // The window's `overrideUserInterfaceStyle` masks system appearance changes
        // from view controllers inside the window, so `MainTabBarController.traitCollectionDidChange`
        // never fires for system light/dark flips. Observe at the scene level instead —
        // scene traits are not affected by the per-window override.
        if LiquidGlass.isEnabled, #available(iOS 17.0, *) {
            systemAppearanceObservation = windowScene.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (scene: UIWindowScene, _: UITraitCollection) in
                let isDark = (scene.traitCollection.userInterfaceStyle == .dark)
                guard Theme.systemIsDark != isDark else { return }
                Theme.systemIsDark = isDark
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.systemThemeMayHaveChanged, object: isDark)
            }
        }

        window.makeKeyAndVisible()

        if let shortcutItem = connectionOptions.shortcutItem {
            appDelegate()?.handleShortcutItem(shortcutItem)
        }
        if let url = connectionOptions.urlContexts.first?.url, let rootViewController = window.rootViewController {
            _ = appDelegate()?.handleOpenUrl(url: url, rootViewController: rootViewController)
        }
        if let userActivity = connectionOptions.userActivities.first {
            appDelegate()?.handleContinue(userActivity)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appDelegate()?.handleBecomeActive()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate()?.handleEnterBackground()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        appDelegate()?.handleContinue(userActivity)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard !URLContexts.isEmpty, let url = URLContexts.first?.url, let rootViewController = window?.rootViewController else {
            return
        }
        _ = appDelegate()?.handleOpenUrl(url: url, rootViewController: rootViewController)
    }

    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        appDelegate()?.handleShortcutItem(shortcutItem)
    }

    @objc private func themeDidChange() {
        window?.applyInterfaceStyleForActiveTheme()
    }
}
