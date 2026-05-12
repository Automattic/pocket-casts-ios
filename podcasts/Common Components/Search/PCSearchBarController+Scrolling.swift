import Foundation

extension PCSearchBarController {
    func setupScrollView(_ scrollView: UIScrollView, hideSearchInitially: Bool) {
        if !hideSearchInitially {
            scrollView.contentInset = UIEdgeInsets(top: PCSearchBarController.defaultHeight, left: scrollView.contentInset.left, bottom: scrollView.contentInset.bottom, right: scrollView.contentInset.right)
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -PCSearchBarController.defaultHeight), animated: false)
        }
    }

    func parentScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let searchControllerHeightConstraint else { return }

        let yPos = scrollView.contentOffset.y + (view.superview?.safeAreaInsets.top ?? 0)

        let newHeight: CGFloat
        if yPos < 0 {
            newHeight = min(PCSearchBarController.defaultHeight, -yPos)
        } else {
            newHeight = 0
        }

        if searchControllerHeightConstraint.constant != newHeight {
            searchControllerHeightConstraint.constant = newHeight
            view.layoutIfNeeded()
            updateCollapseAppearance()
        }

        // Only sync during an active drag — leaving programmatic animations (snap-to-open
        // below, deceleration) to settle on their own, then resync at the end.
        if tracksContentInsetToBarHeight, scrollView.isDragging {
            syncContentInsetToBarHeight(scrollView)
        }
    }

    func parentScrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let topOffset = view.superview?.safeAreaInsets.top ?? 0
        let yPos = scrollView.contentOffset.y + topOffset
        let scrollingDown = scrollView.panGestureRecognizer.velocity(in: scrollView).y >= 0
        let shouldChangeInset = (yPos < -PCSearchBarController.peekAmountBeforeAutoOpen)
        let shouldAnimateDown = (!decelerate && scrollingDown && shouldChangeInset && yPos > -PCSearchBarController.defaultHeight)
        let shouldAnimateUp = (!decelerate && !scrollingDown && yPos > -PCSearchBarController.defaultHeight && yPos < 0)

        if shouldChangeInset, scrollView.contentInset.top != PCSearchBarController.defaultHeight {
            scrollView.contentInset = UIEdgeInsets(top: PCSearchBarController.defaultHeight, left: scrollView.contentInset.left, bottom: scrollView.contentInset.bottom, right: scrollView.contentInset.right)
        }

        if shouldAnimateDown {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -PCSearchBarController.defaultHeight - topOffset), animated: true)
        } else if shouldAnimateUp {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -topOffset), animated: true)
        }
    }

    func parentScrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard tracksContentInsetToBarHeight else { return }
        syncContentInsetToBarHeight(scrollView)
    }

    func parentScrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard tracksContentInsetToBarHeight else { return }
        syncContentInsetToBarHeight(scrollView)
    }

    private func syncContentInsetToBarHeight(_ scrollView: UIScrollView) {
        guard let height = searchControllerHeightConstraint?.constant else { return }
        if scrollView.contentInset.top != height {
            scrollView.contentInset.top = height
        }
    }
}
