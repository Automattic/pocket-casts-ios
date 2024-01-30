import Foundation

extension PlayerContainerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == mainScrollView {
            if !scrollView.isTracking, !scrollView.isDragging { return } // ignore programmatic scroll

            let xOffset = scrollView.contentOffset.x
            let currentTab = Int(round(xOffset / scrollView.bounds.width))
            if currentTab == tabsView.currentTab { return }
            tabsView.currentTab = currentTab

            adjustPlayerNoSlidingRegion()
        } else {
            // this is a secondary child scroll view, pass it on to our gesture handler code
            handleScrollViewDidScroll(scrollView: scrollView)
        }
    }
}
