#if !os(watchOS)
import UIKit

public extension UIScrollView {
    /// Calculates the current visible page based on the content offset
    var currentPage: Int {
        let offset = round(contentOffset.x / contentOffsetWidth)

        guard isPagingEnabled, offset.isNumeric else { return 0 }

        return Int(offset)
    }

    /// Scrolls the given page into view
    func scrollToPage(_ page: Int, animated: Bool = true) {
        guard isPagingEnabled else { return }

        var offset = contentOffset
        offset.x = contentOffsetWidth * Double(page)

        setContentOffset(offset, animated: animated)
    }

    /// Returns the width of the view for use when paging
    private var contentOffsetWidth: Double {
        contentSize.width * 0.5
    }

    /// Toggles the `showsVerticalScrollIndicator` off then on
    /// This will hide the indicators but still allow them to be shown
    func hideVerticalScrollIndicator() {
        guard showsVerticalScrollIndicator else { return }

        showsVerticalScrollIndicator = false
        showsVerticalScrollIndicator = true
    }
}
#endif
