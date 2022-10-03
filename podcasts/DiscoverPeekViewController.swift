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

    private(set) var currentPage: Int = 0

    var cellSpacing = 0 as CGFloat
    var numVisibleColumns = 1 as CGFloat
    var peekWidth = 8 as CGFloat
    var cellWidth: CGFloat {
        let widthAvailable = view.bounds.width
        let maxWidth = maxCellWidth > 0 ? maxCellWidth : widthAvailable
        return min(maxWidth, (widthAvailable - peekWidth - (cellSpacing * (numVisibleColumns + 1))) / numVisibleColumns)
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
        let currentIndex = Int(round(currentScrollOffset.x / ((cellWidth + cellSpacing) * numVisibleColumns)))
        let adjacentItemIndex = currentIndex + coefficent
        let adjacentItemIndexFloat = CGFloat(adjacentItemIndex)
        let adjacentItemOffsetX = adjacentItemIndexFloat * (cellWidth + cellSpacing) * numVisibleColumns
        targetContentOffset.pointee = CGPoint(x: adjacentItemOffsetX, y: target.y)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPage = Int(ceil(collectionView.contentOffset.x / collectionView.frame.width)) + 1
        guard currentPage != self.currentPage else {
            return
        }

        self.currentPage = currentPage

        // Calculate the total number of pages
        // We round the value up in case of an odd number of items which can result in a half page
        let numberOfItems = CGFloat(collectionView.numberOfItems(inSection: 0))
        let total = Int(ceil(numberOfItems / numVisibleColumns))
        pageDidChange(to: currentPage, totalPages: total)
    }

    func pageDidChange(to currentPage: Int, totalPages: Int) {
        /* Subclasses can override this */
    }
}
