import UIKit

struct UIViewControllerContentConfiguration: UIContentConfiguration {
    let viewController: UIViewController
    let parentViewController: UIViewController

    init(parentViewController: UIViewController, viewController: UIViewController) {
        self.parentViewController = parentViewController
        self.viewController = viewController
    }

    func makeContentView() -> UIView & UIContentView {
        ViewControllerContainerContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> UIViewControllerContentConfiguration {
        self
    }
}

final class ViewControllerContainerContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        get { _configuration }
        set {
            guard let newValue = newValue as? UIViewControllerContentConfiguration else {
                return assertionFailure("Unsupported configuration")
            }
            _configuration = newValue
        }
    }

    private var _configuration: UIViewControllerContentConfiguration {
        didSet {
            guard oldValue.viewController !== _configuration.viewController else { return }
            subviews.first?.removeFromSuperview()
            setupConstraints()
        }
    }

    init(configuration: UIViewControllerContentConfiguration) {
        self._configuration = configuration
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        let viewController = _configuration.viewController
        addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        _configuration.parentViewController.addChild(viewController)
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let vc = _configuration.viewController

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
    }
}
