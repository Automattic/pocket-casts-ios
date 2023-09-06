import Foundation

extension MiniPlayerViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MiniPlayerToFullPlayerAnimator()
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MiniPlayerToFullPlayerAnimator()
    }
}
