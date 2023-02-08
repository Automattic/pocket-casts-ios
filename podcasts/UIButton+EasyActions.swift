import UIKit

extension UIButton {
    func addAction(_ action: @escaping () -> Void, for event: UIControl.Event = .touchUpInside) {
        addAction(UIAction(handler: { _ in
            action()
        }), for: event)
    }
}
