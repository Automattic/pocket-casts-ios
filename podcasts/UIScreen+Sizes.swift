import Foundation

extension UIScreen {
    static var isSmallScreen: Bool {
       UIScreen.main.bounds.height <= 667
    }
}
