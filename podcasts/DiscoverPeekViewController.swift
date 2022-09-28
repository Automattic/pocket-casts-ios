import Foundation

class DiscoverPeekViewController: UIViewController, UICollectionViewDelegate {
    @IBOutlet var collectionView: ThemeableCollectionView! {
        didSet {
            collectionView.style = .primaryUi02
        }
    }

    var isPeekEnabled = false {
        didSet {
            collectionView.isPagingEnabled = false
            collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        }
    }

    var cellSpacing = 0 as CGFloat
    var numVisibleColoumns = 1 as CGFloat
    var peekWidth = 8 as CGFloat
    var cellWidth: CGFloat {
        let widthAvailable = view.bounds.width
        let maxWidth = maxCellWidth > 0 ? maxCellWidth : widthAvailable
        return min(maxWidth, (widthAvailable - peekWidth - (cellSpacing * (numVisibleColoumns + 1))) / numVisibleColoumns)
    }

    // this is a sensible default for all the current places in the app, though children can override this value if they choose to
    // setting it to 0 = off
    var maxCellWidth = 200 as CGFloat

    private var currentScrollOffset: CGPoint!
    private var scrollThreshold = 40 as CGFloat

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currentScrollOffset = scrollView.contentOffset
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard isPeekEnabled == true else { return }

        guard let currentScrollOffset = currentScrollOffset else { return }
        let target = targetContentOffset.pointee
        let currentScrollDistance = target.x - currentScrollOffset.x
        let coefficent = Int(max(-1, min(currentScrollDistance / scrollThreshold, 1)))
        let currentIndex = Int(round(currentScrollOffset.x / ((cellWidth + cellSpacing) * numVisibleColoumns)))
        let adjacentItemIndex = currentIndex + coefficent
        let adjacentItemIndexFloat = CGFloat(adjacentItemIndex)
        let adjacentItemOffsetX = adjacentItemIndexFloat * (cellWidth + cellSpacing) * numVisibleColoumns
        targetContentOffset.pointee = CGPoint(x: adjacentItemOffsetX, y: target.y)
    }
}
