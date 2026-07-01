import UIKit

extension UIViewController {
    /// Hides or shows the enclosing tab bar using the iOS 18 API.
    /// On earlier OS versions, or when the view controller isn't inside a
    /// tab bar controller, this is a no-op.
    func setEnclosingTabBarHidden(_ hidden: Bool, animated: Bool) {
        // Workaround: `setTabBarHidden(_:animated:)` is buggy on iOS 27, so we
        // disable tab bar hiding there for now. There's a follow-up ticket to
        // re-enable this once Apple fixes the underlying issues.
        guard #unavailable(iOS 27) else { return }

        guard #available(iOS 26, *), let tabBarController else { return }
        tabBarController.setTabBarHidden(hidden, animated: animated)
    }
}
