import Foundation

extension MiniPlayerViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: dismissed, transition: .dismissing)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: presented, transition: .presenting)
    }
}
