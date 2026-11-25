import UIKit

private var contentUnavailableKey: UInt8 = 0

extension UIViewController {
    private var pc_contentUnavailableView: UIView? {
        get { objc_getAssociatedObject(self, &contentUnavailableKey) as? UIView }
        set { objc_setAssociatedObject(self, &contentUnavailableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func setContentUnavailableConfiguration(_ configuration: UIContentConfiguration?) {
        // Remove previous view if any
        pc_contentUnavailableView?.removeFromSuperview()
        pc_contentUnavailableView = nil

        guard let configuration else { return }

        let configView = configuration.makeContentView()
        configView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(configView)

        // Pin vertically so the SwiftUI content is offered the full available height. Without
        // this, the view's height comes only from its intrinsic size, and views that adapt to
        // the offered height (such as `ViewThatFits` in `EmptyStateView`) can collapse into a
        // tiny scroll view. SwiftUI centers the content within these bounds.
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            configView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            configView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            configView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            configView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        pc_contentUnavailableView = configView
    }
}
