import UIKit

class CategoryPodcastsTable: ThemeableTable {
    override var intrinsicContentSize: CGSize {
        if dataSource != nil {
            self.layoutIfNeeded()
        }
        return self.contentSize
    }

    override var contentSize: CGSize {
        didSet {
            UIView.performWithoutAnimation {
                self.invalidateIntrinsicContentSize()
            }
        }
    }
}
