#if !os(watchOS)
    import UIKit

    public extension UIApplication {
        func endEditing() {
            sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
#endif
