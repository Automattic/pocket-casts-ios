import Foundation

/// Extension that allows the UIAlertAction to be tested
extension UIAlertAction {
    @objc class func make(title: String?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: title, style: style, handler: handler)
    }
}
