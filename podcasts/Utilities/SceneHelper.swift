import PocketCastsUtils
import UIKit

@MainActor
enum SceneHelper {
    static func connectedScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap {
            $0 as? UIWindowScene
        }.first
    }

    static func newMainScreenWindow() -> UIWindow {
        if let scene = connectedScene() {
            return UIWindow(windowScene: scene)
        }

        return UIWindow(frame: UIScreen.main.bounds)
    }

    static func rootViewController(includeTopMost: Bool = true) -> UIViewController? {
        #if os(tvOS)
            return nil
        #else
        let appScene = connectedScene()?.windows.first(where: { $0.rootViewController is MainTabBarController })
        let rootVC = appScene?.rootViewController
        if includeTopMost {
            return rootVC?.topMostPresentedViewController ?? rootVC
        }
        return rootVC
        #endif
    }

    /// Returns the main window for the app from the AppDelegate
    static var mainWindow: UIWindow? {
        #if os(tvOS)
            return nil
        #else
            (UIApplication.shared.delegate as? AppDelegate)?.window
        #endif
    }
}
