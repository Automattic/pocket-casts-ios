import Foundation

extension NSObject {
    func appDelegate() -> AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
}
