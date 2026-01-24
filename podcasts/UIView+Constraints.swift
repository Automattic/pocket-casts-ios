import UIKit

extension UIView {

    func updateSizeConstraints(of view: UIView, to value: CGFloat) {
        for constraint in view.constraints {
            if constraint.secondItem != nil {
                continue
            }
            switch constraint.firstAttribute {
            case .width:
                constraint.constant = value
            case .height:
                constraint.constant = value
            default:
                continue
            }
        }
    }

}
