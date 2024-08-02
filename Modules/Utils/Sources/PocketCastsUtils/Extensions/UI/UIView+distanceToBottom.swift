#if !os(watchOS)
import UIKit

extension UIView {
    public func distanceFromBottom() -> CGFloat? {
        guard let window = self.window else {
            return nil
        }

        let viewFrameInWindow = self.convert(self.bounds, to: window)

        let screenHeight = UIScreen.main.bounds.height
        let distanceFromBottom = screenHeight - viewFrameInWindow.maxY

        return distanceFromBottom
    }
}
#endif
