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
        let appScene = connectedScene()?.windows.first(where: { $0.rootViewController is MainTabBarController })
        let rootVC = appScene?.rootViewController
        return rootVC?.topMostPresentedViewController ?? rootVC
    }

    /// Returns the main window for the app from the AppDelegate
    static var mainWindow: UIWindow? {
        (UIApplication.shared.delegate as? AppDelegate)?.window
    }
}
