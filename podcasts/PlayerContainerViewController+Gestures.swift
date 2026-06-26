import Foundation
import PocketCastsUtils

extension PlayerContainerViewController: UIGestureRecognizerDelegate {
    private static let minimumVelocityToHide: CGFloat = 1000
    private static let minimumScreenRatioToHide: CGFloat = 0.1

    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        guard let miniPlayer = appDelegate()?.miniPlayer(), !(miniPlayer.playerOpenState == .beingDragged || miniPlayer.playerOpenState == .animating) else { return }

        if nowPlayingItem.timeSlider.isScrubbing() { return }

        let touchPoint = sender.location(in: view?.window)

        switch sender.state {
        case .began:
            initialTouchPoint = touchPoint
            // Round the player's corners for the drag so it reads as a card
            // lifting off the screen. They're squared again if the drag springs
            // back, or carried into the dismiss transition if it closes.
            if #available(iOS 26, *) {
                roundCornersForPlayerTransition()
            }
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
            // An upward flick at release cancels the dismiss even if the
            // player was dragged past the threshold — the user is flicking
            // back up to keep the player open.
            let pastThreshold = translation.y > view.frame.size.height * Self.minimumScreenRatioToHide
            let downwardFlick = velocity.y > Self.minimumVelocityToHide
            let upwardFlick = velocity.y < 0
            let closing = !upwardFlick && (pastThreshold || downwardFlick)
            dismissVelocity = velocity.y

            if closing {
                finalYPositionWhenDismissing = touchPoint.y - initialTouchPoint.y
                miniPlayer.closeFullScreenPlayer()
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.frame = CGRect(x: 0,
                                             y: 0,
                                             width: self.view.frame.size.width,
                                             height: self.view.frame.size.height)
                }, completion: { _ in
                    // Settled back full-screen: square the corners so the player
                    // covers the whole screen with no edge gaps.
                    if #available(iOS 26, *) {
                        self.resetCornersAfterPlayerTransition()
                    }
                })
            }
            if let scroll = activeInnerScrollView {
                scroll.bounces = savedInnerScrollViewBounces
            }
            activeInnerScrollView = nil
        default:
            break
        }
    }

    // this is used so that the player tab line only fades in when you tap something that isn't a control
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIControl)
    }

    // Prioritize the vertical dismiss gesture over the horizontal page swipe between
    // tabs: begin as long as the motion is downward and the vertical component is at
    // least half the horizontal one (~26° from horizontal). This way diagonal swipes
    // still dismiss the player instead of being captured by the tab scroll view.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: view)
        guard velocity.y > 0 && velocity.y * 2 >= abs(velocity.x) else { return false }

        let scroll = innerVerticalScrollView(at: pan.location(in: view))
        // If the touch is on an inner vertical scroll view that has scrolled past
        // its top, let the scroll view consume the gesture instead of dismissing.
        if let scroll, scroll.contentOffset.y > scrollViewTopOffset(scroll) + 0.5 {
            return false
        }

        // We're committing to recognize. Disable bouncing on the inner scroll view
        // now (rather than clamping in `.changed`) so its pan can't produce even a
        // single frame of bounce before our handler runs.
        if let scroll {
            activeInnerScrollView = scroll
            savedInnerScrollViewBounces = scroll.bounces
            scroll.bounces = false
        }
        return true
    }

    // Recognize alongside inner scroll views' pan gestures so we can pin them to
    // their top while the container is being dragged — otherwise both the
    // container and the scroll content would move at once.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scroll = otherGestureRecognizer.view as? UIScrollView, scroll !== mainScrollView {
            return true
        }
        return false
    }

    func innerVerticalScrollView(at point: CGPoint) -> UIScrollView? {
        guard let hit = view.hitTest(point, with: nil) else { return nil }
        var current: UIView? = hit
        while let v = current, v !== view {
            if let scroll = v as? UIScrollView, scroll !== mainScrollView, scroll.isScrollEnabled {
                return scroll
            }
            current = v.superview
        }
        return nil
    }

    private func scrollViewTopOffset(_ scrollView: UIScrollView) -> CGFloat {
        -scrollView.adjustedContentInset.top
    }
}
