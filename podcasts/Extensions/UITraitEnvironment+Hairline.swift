import UIKit

extension UITraitEnvironment {
    /// The thinnest line that renders as a single pixel on this environment's display.
    var hairlineWidth: CGFloat {
        1 / max(traitCollection.displayScale, 1)
    }
}

extension UITraitChangeObservable where Self: UITraitEnvironment {
    /// Sets the constraint's constant to `hairlineWidth` and keeps it updated when the display scale changes.
    func applyHairlineWidth(to constraint: NSLayoutConstraint) {
        constraint.constant = hairlineWidth
        registerForTraitChanges([UITraitDisplayScale.self]) { (environment: Self, _) in
            constraint.constant = environment.hairlineWidth
        }
    }
}
