import Foundation

#if !os(watchOS)
extension UIApplication {
    func getTopViewController(base: UIViewController? = SceneHelper.rootViewController()) -> UIViewController? {
        guard UIApplication.shared.applicationState == .active else {
            return nil
        }

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
#endif
