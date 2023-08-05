import PocketCastsUtils
import UIKit
import CarPlay

class SceneHelper {
    class func connectedScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap {
            $0 as? UIWindowScene
        }.first
    }

    class func newMainScreenWindow() -> UIWindow {
        if let scene = connectedScene() {
            return UIWindow(windowScene: scene)
        }

        return UIWindow(frame: UIScreen.main.bounds)
    }

    class func rootViewController() -> UIViewController? {
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

    /// Returns the main window for the app from the AppDelegate
    static var mainWindow: UIWindow? {
        (UIApplication.shared.delegate as? AppDelegate)?.window
    }
}
