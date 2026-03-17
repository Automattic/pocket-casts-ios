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

        guard let configuration = configuration else { return }

        let configView = configuration.makeContentView()
        configView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(configView)

        NSLayoutConstraint.activate([
            configView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            configView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            configView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            configView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])

        pc_contentUnavailableView = configView
    }
}
