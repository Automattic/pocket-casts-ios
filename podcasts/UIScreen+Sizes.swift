import Foundation
import UIKit

extension UIScreen {
    static var isSmallScreen: Bool {
       UIScreen.main.bounds.height <= 667
    }
}
