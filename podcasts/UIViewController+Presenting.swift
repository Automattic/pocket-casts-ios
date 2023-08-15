import UIKit

extension UIViewController {
    /// Presents the given view controller from the root view controller, or the currently presented view controller if there is one.
    func presentFromRootController(_ controller: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let presentingController = presentedViewController ?? SceneHelper.rootViewController() else {
            completion?()
            return
        }

        presentingController.present(controller, animated: animated, completion: completion)
    }

    /// Dismisses the presented controller if there is one, then calls the completion block
    /// - Parameters:
    ///   - sourceController: The source controller to dismiss from. This defaults to `self` if its nil.
    ///   - animated: Whether to animate the dismiss or not
    ///   - completion: The optional completion block to call after the view is dismissed.
    func dismissIfNeeded(sourceController: UIViewController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        let sourceController = sourceController ?? self

        guard sourceController.presentedViewController != nil else {
            completion?()
            return
        }

        sourceController.dismiss(animated: animated, completion: completion)
    }
}
