import Foundation

extension PlayerContainerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == mainScrollView {
            if !scrollView.isTracking, !scrollView.isDragging { return } // ignore programmatic scroll

            let xOffset = scrollView.contentOffset.x
            if xOffset < 0 {
                tabsView.leadingEdgePullDistance = -xOffset
            } else if xOffset > maxScrollWidth() {
                tabsView.trailingEdgePullDistance = xOffset - maxScrollWidth()
            } else if tabsView.leadingEdgePullDistance != 0 || tabsView.trailingEdgePullDistance != 0 {
                tabsView.leadingEdgePullDistance = 0
                tabsView.trailingEdgePullDistance = 0
            }

            let currentTab = Int(round(xOffset / scrollView.bounds.width))
            if currentTab == tabsView.currentTab { return }
            tabsView.currentTab = currentTab

            adjustPlayerNoSlidingRegion()
        } else {
            // this is a secondary child scroll view, pass it on to our gesture handler code
            handleScrollViewDidScroll(scrollView: scrollView)
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let endPoint = targetContentOffset.pointee

        if (endPoint.x == 0 && tabsView.leadingEdgePullDistance > 0) || (endPoint.x == maxScrollWidth() && tabsView.trailingEdgePullDistance > 0) {
            tabsView.animateBackToNonCompressed()
        }
    }

    private func maxScrollWidth() -> CGFloat {
        let tabCount = tabsView.tabs.count
        return CGFloat(max(1, tabCount - 1)) * view.bounds.width
    }
}
