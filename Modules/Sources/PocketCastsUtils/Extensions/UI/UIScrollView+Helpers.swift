#if !os(watchOS)
import UIKit

public extension UIScrollView {
    /// Toggles the `showsVerticalScrollIndicator` off then on
    /// This will hide the indicators but still allow them to be shown
    func hideVerticalScrollIndicator() {
        guard showsVerticalScrollIndicator else { return }

        showsVerticalScrollIndicator = false
        showsVerticalScrollIndicator = true
    }
}
#endif
