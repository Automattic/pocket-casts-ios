@testable import podcasts
import UIKit

class MockUIAlertAction: UIAlertAction {
    var mockHandler: ((UIAlertAction) -> Void)?
    var mockTitle: String?
    var mockStyle: UIAlertAction.Style?

    convenience init(title: String?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) {
        self.init()

        mockTitle = title
        mockStyle = style
        mockHandler = handler
    }
    
    override class func make(title: String?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return MockUIAlertAction(title: title, style: style, handler: handler)
    }
}
