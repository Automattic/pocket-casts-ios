import PocketCastsUtils
import UIKit
class SceneHelper {
    class func foregroundActiveAppScene() -> UIWindowScene? {
        guard let scene = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive }).first as? UIWindowScene else {
            return nil
        }
        return scene
    }

    class func connectedScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        for scene in scenes {
            if scene.isKind(of: UIWindowScene.self) {
                return scene
            }
        }
        return nil
    }

    class func newMainScreenWindow() -> UIWindow {
        if let scene = foregroundActiveAppScene() {
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
}
