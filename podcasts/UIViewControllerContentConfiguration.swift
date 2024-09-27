final class UIViewControllerContentConfiguration: UIContentConfiguration {
    let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func makeContentView() -> UIView & UIContentView {
        return ViewControllerContainerContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> UIViewControllerContentConfiguration {
        return self
    }
}

class ViewControllerContainerContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet {
            subviews.first?.removeFromSuperview()
            setupConstraints()
        }
    }

    init(configuration: UIViewControllerContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        guard let configuration = configuration as? UIViewControllerContentConfiguration else { return }

        let viewController = configuration.viewController
//        viewController.view.autoresizingMask = [.flexibleWidth]
        addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        if let vc = (configuration as? UIViewControllerContentConfiguration)?.viewController {
            vc.view.layoutSubviews()

            let fittingSize = CGSize(width: targetSize.width, height: UIView.layoutFittingCompressedSize.height)
            var size = vc.view.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)

            if size.height == CGFloat.greatestFiniteMagnitude || size.width == CGFloat.greatestFiniteMagnitude {
                size = vc.view.frame.size
            }

            if horizontalFittingPriority >= UILayoutPriority.defaultHigh {
                size.width = targetSize.width
            }

            return size
        } else {
            return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        }
    }
}
