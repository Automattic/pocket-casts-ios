import UIKit

extension UIScrollView {
    var isRightToLeft: Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    /// Converts between a content offset and the offset the same position has in a left-to-right layout. The conversion is its own inverse.
    func leadingAlignedOffsetX(_ x: CGFloat) -> CGFloat {
        isRightToLeft ? contentSize.width - bounds.width - x : x
    }

    var leadingContentInset: CGFloat {
        isRightToLeft ? contentInset.right : contentInset.left
    }

    func setContentInsets(leading: CGFloat, trailing: CGFloat) {
        if isRightToLeft {
            contentInset.right = leading
            contentInset.left = trailing
        } else {
            contentInset.left = leading
            contentInset.right = trailing
        }
    }

    func scrollToLeadingEdge() {
        layoutIfNeeded()
        contentOffset.x = leadingAlignedOffsetX(-leadingContentInset)
    }
}

extension UICollectionView {
    var leadingScrollPosition: ScrollPosition {
        isRightToLeft ? .right : .left
    }
}
