#if !os(watchOS)
import UIKit

/// A UIScrollView subclass that allows the swipe to dismiss in a presented view when its contained in a parent UIScrollView
public class DismissableNestedScrollView: UIScrollView, UIGestureRecognizerDelegate {
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return (contentOffset.y + contentInset.top) - panGestureRecognizer.translation(in: self).y > 0
    }
}
#endif
