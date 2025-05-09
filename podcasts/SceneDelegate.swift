import JLRoutes
import UIKit
import FacebookCore
import PocketCastsUtils

class SceneDelegate: UIResponder, UISceneDelegate, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        if FeatureFlag.podcastNewformAppsFlyer.enabled {
            if let userActivity = connectionOptions.userActivities.first,
               userActivity.activityType == NSUserActivityTypeBrowsingWeb {
                ApplicationDelegate.shared.application(.shared, continue: userActivity)
            }
        }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.rootViewController = MainTabBarController()

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
        if Theme.sharedTheme.activeTheme == .radioactive {
            appDelegate()?.lenticularFilter.show()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate()?.handleEnterBackground()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if FeatureFlag.podcastNewformAppsFlyer.enabled {
            ApplicationDelegate.shared.application(.shared, continue: userActivity)
        }
        appDelegate()?.handleContinue(userActivity)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard URLContexts.count > 0, let url = URLContexts.first?.url, let rootViewController = window?.rootViewController else {
            return
        }
        _ = appDelegate()?.handleOpenUrl(url: url, rootViewController: rootViewController)
    }

    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        appDelegate()?.handleShortcutItem(shortcutItem)
    }
}
