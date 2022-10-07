
import UIKit

class RegionCancellingScrollView: UIScrollView, UIGestureRecognizerDelegate {
    var regionsToCancelIn: CGRect?

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let regionsToCancelIn = regionsToCancelIn else { return true }

        // cancel all gesture recognisers for the area we've agreed not to touch
        let location = touch.location(in: self)
        return !regionsToCancelIn.contains(location)
    }
}
