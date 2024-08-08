import Foundation
import UIKit
import PocketCastsUtils

class TranscriptErrorView: UIView {

    private lazy var containerView: UIView = {
        let view = UIStackView(arrangedSubviews: [icon, label, retryButton])
        view.spacing = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.distribution = .equalCentering
        view.alignment = .center
        return view
    }()

    private lazy var icon: UIImageView = {
        let view = UIImageView(image: UIImage(named: "yield_scaled"))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var retryButton: UIView = {
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(top: 4, leading: 12, bottom: 4, trailing: 12)

        let retryButton = RoundButton(type: .system)
        retryButton.setTitle(L10n.tryAgain, for: .normal)
        retryButton.addTarget(self, action: #selector(retryLoad), for: .touchUpInside)

        retryButton.setTitleColor(.white, for: .normal)
        retryButton.tintColor = .white.withAlphaComponent(0.2)
        retryButton.layer.masksToBounds = true
        retryButton.configuration = configuration
        retryButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        return retryButton
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate(
            [
                containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
                containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
                containerView.widthAnchor.constraint(equalTo: widthAnchor),
                containerView.heightAnchor.constraint(equalTo: heightAnchor)
            ]
        )

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMessage(_ message: String, attributes: [NSAttributedString.Key: Any]) {
        label.attributedText = NSAttributedString(string: message, attributes: attributes)
    }

    func setTextAttributes(_ attributes: [NSAttributedString.Key: Any]) {
        if let text = label.text {
            label.attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }

    @objc func retryLoad() {

    }

    override var intrinsicContentSize: CGSize {
        return containerView.intrinsicContentSize
    }
}
