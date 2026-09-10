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

/// A screen that hides the tab bar and the mini player while a mode of its own is active,
/// such as multi-select. The tab bar is shared with every other screen, so the mode only
/// gets to hide it for as long as the screen is the one on-screen.
@MainActor
protocol EnclosingTabBarHiding: UIViewController {
    var hidesEnclosingTabBar: Bool { get }
}

extension EnclosingTabBarHiding {
    /// Takes the tab bar back when the screen appears and hands it over when it
    /// disappears. Call from `viewWillAppear` and `viewWillDisappear`.
    func updateEnclosingTabBarHidden(isOnScreen: Bool) {
        guard hidesEnclosingTabBar else { return }

        setEnclosingTabBarHidden(isOnScreen, animated: false)
    }
}
