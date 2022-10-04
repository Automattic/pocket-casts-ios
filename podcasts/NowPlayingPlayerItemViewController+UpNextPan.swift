import Foundation

extension NowPlayingPlayerItemViewController: UIGestureRecognizerDelegate {
    private static let pullUpThresholdPercent: Float = 0.1

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !timeSlider.isScrubbing(), presentedViewController == nil else { return false }

        guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }

        let velocity = recognizer.velocity(in: view)
        let vertical = abs(velocity.y) > abs(velocity.x)

        if !vertical { return false }

        return velocity.y < 0 // we are only looking for swipe up gestures
    }

    @objc func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        guard presentedViewController == nil, sender.state == .began || sender.state == .changed else { return }

        let movementOnAxis = sender.translation(in: view).y / view.bounds.height
        let positiveMovementOnAxis = fminf(Float(movementOnAxis), 0.0)
        let positiveMovementOnAxisPercent = fmaxf(positiveMovementOnAxis, -1.0)

        let progress = -positiveMovementOnAxisPercent
        let movedFarEnough = progress > NowPlayingPlayerItemViewController.pullUpThresholdPercent
        if movedFarEnough {
            present(upNextViewController, animated: true, completion: nil)
        }
    }
}
