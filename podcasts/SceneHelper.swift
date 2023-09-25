import PocketCastsUtils
import UIKit
import CarPlay

class SceneHelper {
    class func connectedScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap {
            $0 as? UIWindowScene
        }.first
    }

    static var isConnectedToCarPlay: Bool {
        UIApplication.shared.connectedScenes.contains(where: {
            $0 is CPTemplateApplicationScene
        })
    }

    class func newMainScreenWindow() -> UIWindow {
        if let scene = connectedScene() {
            return UIWindow(windowScene: scene)
        }

        return UIWindow(frame: UIScreen.main.bounds)
    }

    class func rootViewController() -> UIViewController? {
        guard !FeatureFlag.newPlayerTransition.enabled else {
            return connectedScene()?.windows.mapFirst { getPresentedViewController(base: $0.rootViewController) }
        }

        if let scene = connectedScene() {
            for window in scene.windows {
                if let mainTabController = window.rootViewController as? MainTabBarController {
                    return mainTabController
                }
            }
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        return appDelegate.window?.rootViewController
    }

    class func getPresentedViewController(base: UIViewController?) -> UIViewController? {
            guard UIApplication.shared.applicationState == .active else {
                return nil
            }

            if let nav = base as? UINavigationController {
                return getPresentedViewController(base: nav.visibleViewController)
            } else if let presented = base?.presentedViewController {
                return getPresentedViewController(base: presented)
            }
            return base
        }

    /// Returns the main window for the app from the AppDelegate
    static var mainWindow: UIWindow? {
        (UIApplication.shared.delegate as? AppDelegate)?.window
    }
}
