import UIKit

extension UIViewController {
    /// Hides or shows the enclosing tab bar using the iOS 18 API.
    /// On earlier OS versions, or when the view controller isn't inside a
    /// tab bar controller, this is a no-op.
    func setEnclosingTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard #available(iOS 26, *), let tabBarController else { return }

        tabBarController.setTabBarHidden(hidden, animated: animated)

        let miniPlayer = appDelegate()?.miniPlayer()
        if hidden {
            miniPlayer?.hideMiniPlayer(animated, isTransient: true)
        } else {
            miniPlayer?.showMiniPlayer()
        }
    }
}
