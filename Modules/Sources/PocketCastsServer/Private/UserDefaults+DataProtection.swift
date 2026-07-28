import Foundation
#if !os(watchOS)
import UIKit
#endif

extension UserDefaults {
    static func isProtectedDataAvailable() -> Bool? {
        #if !os(watchOS)
        return UIApplication.shared.isProtectedDataAvailable
        #else
        return nil
        #endif
    }
}
