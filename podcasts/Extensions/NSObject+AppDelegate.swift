import Foundation
import UIKit

extension NSObject {
    func appDelegate() -> AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
}
