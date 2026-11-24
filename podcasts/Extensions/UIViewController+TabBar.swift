import UIKit

extension UIViewController {
    /// Hides or shows the enclosing tab bar, and the mini player with it.
    /// Does nothing before iOS 26, or when the view controller isn't inside a
    /// tab bar controller.
    ///
    /// The mini player stays hidden until this is called again with `hidden: false`,
    /// so every call that hides must be paired with one that shows, e.g. in `viewWillDisappear`.
    func setEnclosingTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard #available(iOS 26, *), let tabBarController else { return }

        tabBarController.setTabBarHidden(hidden, animated: animated)

        appDelegate()?.miniPlayer()?.setHiddenWithTabBar(hidden, animated: animated)
    }
}
