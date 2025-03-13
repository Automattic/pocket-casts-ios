import UIKit
import PocketCastsServer

class GeneratedTranscriptsPremiumOverlay: UIViewController {
    var dismissTranscript: (() -> Void)?
    var purchaseSuccessfull: (() -> Void)?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()

    private lazy var closeButton: TintableImageButton! = {
        let closeButton = TintableImageButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.tintColor = ThemeColor.primaryIcon02()
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return closeButton
    }()

    private lazy var badge: UIView = {
        let badge = SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black).uiView
        badge.translatesAutoresizingMaskIntoConstraints = false
        return badge
    }()

    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = L10n.generatedTranscriptsOverlayTitle
        title.numberOfLines = 0
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = .white
        title.backgroundColor = .clear
        title.textAlignment = .center
        return title
    }()

    private lazy var descriptionLabel: UILabel = {
        let description = UILabel()
        description.translatesAutoresizingMaskIntoConstraints = false
        description.text = L10n.generatedTranscriptsOverlayDescription
        description.numberOfLines = 0
        description.font = .systemFont(ofSize: 14, weight: .regular)
        description.textColor = .white.withAlphaComponent(0.5)
        description.backgroundColor = .clear
        description.textAlignment = .center
        return description
    }()

    private lazy var paywallButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(hex: "#FFD846")
        button.layer.cornerRadius = 12
        button.setTitle(L10n.plusSubscribeTo, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(UIColor(hex: "#181818"), for: .normal)
        button.addTarget(self, action: #selector(paywallButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func didAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(subscriptionStatusDidChange), name: ServerNotifications.subscriptionStatusChanged, object: nil)
    }

    func didDisappear() {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupView() {
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01().withAlphaComponent(0.90)

        stackView.addArrangedSubview(closeButton)
        stackView.addArrangedSubview(UIView())

        view.addSubview(stackView)
        view.addSubview(badge)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(paywallButton)

        let readableContentGuideMargin = 12.0

        NSLayoutConstraint.activate(
            [
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
                stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                closeButton.heightAnchor.constraint(equalToConstant: 44),
                closeButton.widthAnchor.constraint(equalToConstant: 44),
                badge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                badge.topAnchor.constraint(equalTo: stackView.topAnchor, constant: 56),
                titleLabel.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 24),
                titleLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: readableContentGuideMargin),
                titleLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -readableContentGuideMargin),
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
                descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
                paywallButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                paywallButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                paywallButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
                paywallButton.heightAnchor.constraint(equalToConstant: 56)
            ]
        )
    }

    @objc private func closeTapped() {
        dismissTranscript?()
    }

    @objc private func paywallButtonTapped() {
        NavigationManager.sharedManager.showUpsellView(from: self, source: .generatedTranscripts)
    }

    @objc private func subscriptionStatusDidChange() {
        DispatchQueue.main.async { [weak self] in
            if SubscriptionHelper.hasActiveSubscription(), SyncManager.isUserLoggedIn() {
                self?.purchaseSuccessfull?()
            }
        }
    }
}
