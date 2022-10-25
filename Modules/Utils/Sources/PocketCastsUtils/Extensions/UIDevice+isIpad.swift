import UIKit

#if !os(watchOS)
extension UIDevice {
    public func isiPad() -> Bool {
        userInterfaceIdiom == .pad
    }
}
#endif
