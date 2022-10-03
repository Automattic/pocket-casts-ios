
import UIKit

class IndentedTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 20, dy: 5)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 20, dy: 5)
    }
}
