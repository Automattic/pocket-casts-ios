import Foundation
import PocketCastsUtils

extension PlayerContainerViewController: UIGestureRecognizerDelegate {
    private static let pullDownThreshold: CGFloat = 150
    private static let minimumVelocityToHide: CGFloat = 1000
    private static let minimumScreenRatioToHide: CGFloat = 0.1

    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        FeatureFlag.newPlayerTransition.enabled ? newTransitionPanGestureRecognizerHandler(sender) : oldTransitionPanGestureRecognizerHandler(sender)
    }

    func newTransitionPanGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
            guard let miniPlayer = appDelegate()?.miniPlayer(), !(miniPlayer.playerOpenState == .beingDragged || miniPlayer.playerOpenState == .animating) else { return }

            if nowPlayingItem.timeSlider.isScrubbing() { return }

            let touchPoint = sender.location(in: view?.window)

            switch sender.state {
            case .began:
                initialTouchPoint = touchPoint
            case .changed:
                if touchPoint.y > initialTouchPoint.y {
                    view.frame.origin.y = touchPoint.y - initialTouchPoint.y
                }
            case .ended, .cancelled:
                // If pan ended, decide it we should close or reset the view
                // based on the final position and the speed of the gesture
                // (https://stackoverflow.com/a/47339617)
                // If the swipe is too quick, we dismiss
                let translation = sender.translation(in: view)
                let velocity = sender.velocity(in: view)
                let closing = (translation.y > view.frame.size.height * Self.minimumScreenRatioToHide) ||
                (velocity.y > Self.minimumVelocityToHide) || velocity.y > 1000
                dismissVelocity = velocity.y

                if closing {
                    miniPlayer.closeFullScreenPlayer()
                } else {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.view.frame = CGRect(x: 0,
                                                 y: 0,
                                                 width: self.view.frame.size.width,
                                                 height: self.view.frame.size.height)
                    })
                }
            default:
                break
            }
        }

    func oldTransitionPanGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        guard let miniPlayer = appDelegate()?.miniPlayer(), !(miniPlayer.playerOpenState == .beingDragged || miniPlayer.playerOpenState == .animating) else { return }

        if nowPlayingItem.timeSlider.isScrubbing() { return }

        let touchPoint = sender.location(in: view?.window)

        switch sender.state {
        case .began:
            initialTouchPoint = touchPoint
        case .changed:
            if touchPoint.y - initialTouchPoint.y > 0 {
                let yPosition = touchPoint.y - initialTouchPoint.y
                handleMoveTo(yPosition: yPosition, miniPlayer: miniPlayer)
            }
        case .ended, .cancelled:
            if touchPoint.y - initialTouchPoint.y > PlayerContainerViewController.pullDownThreshold {
                miniPlayer.closeFullScreenPlayer()
            } else {
                UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
                    self.view.moveTo(y: 0)
                    miniPlayer.moveToHiddenTopPosition()
                }
            }
        default:
            break
        }
    }

    // this is used so that the player tab line only fades in when you tap something that isn't a control
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIControl)
    }

    func handleScrollViewDidScroll(scrollView: UIScrollView) {
        guard let miniPlayer = appDelegate()?.miniPlayer(), !(miniPlayer.playerOpenState == .beingDragged || miniPlayer.playerOpenState == .animating) else { return }

        if scrollView.contentOffset.y >= 0 {
            miniPlayer.moveToHiddenTopPosition()
        } else {
            let yPosition = floor(-scrollView.contentOffset.y)
            handleMoveTo(yPosition: yPosition, miniPlayer: miniPlayer)
        }
    }

    private func handleMoveTo(yPosition: CGFloat, miniPlayer: MiniPlayerViewController) {
        if miniPlayer.view.isHidden { miniPlayer.view.isHidden = false }

        view.moveTo(y: yPosition)

        if let window = view.window {
            let bottomSafeAreaOffset = window.safeAreaInsets.bottom
            let deviceSpecificPadding = bottomSafeAreaOffset > 0 ? (bottomSafeAreaOffset / 2) : -UIUtil.statusBarHeight(in: window)
            let offset = view.frame.minY - view.frame.size.height + miniPlayer.view.bounds.height + deviceSpecificPadding
            miniPlayer.moveWhileDragging(offsetFromTop: offset)
        }

        if yPosition > PlayerContainerViewController.pullDownThreshold {
            miniPlayer.closeFullScreenPlayer()
        }
    }
}
