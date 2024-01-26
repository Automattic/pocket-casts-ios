import Foundation

extension UIScreen {
    static var isSmallScreen: Bool {
        return UIScreen.main.bounds.height < 667
    }
}
