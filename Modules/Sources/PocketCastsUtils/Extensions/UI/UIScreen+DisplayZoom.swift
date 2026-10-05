#if !os(watchOS)
    import UIKit

    public extension UIScreen {
        /// Whether Display Zoom is on, which makes everything on this screen larger.
        var isDisplayZoomed: Bool {
            nativeScale > scale
        }
    }
#endif
