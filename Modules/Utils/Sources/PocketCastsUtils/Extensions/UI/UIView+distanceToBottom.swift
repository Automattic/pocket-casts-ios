#if !os(watchOS)
import UIKit

extension UIView {
    public func distanceFromBottom() -> CGFloat? {
        guard let window else {
            return nil
        }

        let viewFrameInWindow = convert(self.bounds, to: window)

        let screenHeight = UIScreen.main.bounds.height

        return screenHeight - viewFrameInWindow.maxY
    }
}
#endif
