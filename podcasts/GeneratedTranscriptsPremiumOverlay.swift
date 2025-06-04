import UIKit
import PocketCastsUtils
import PocketCastsServer

class GeneratedTranscriptsPremiumOverlay: UIViewController, AnalyticsSourceProvider {
    var dismissTranscript: (() -> Void)?
    var purchaseSuccessfull: (() -> Void)?

    private let playbackManager: PlaybackManager
    let analyticsSource: AnalyticsSource

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
        closeButton.tintColor = closeButtonColor
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return closeButton
    }()

    private lazy var badge: UIImageView = {
        let badge = UIImageView(image: UIImage(named: "plusBadge"))
        badge.backgroundColor = .clear
        badge.translatesAutoresizingMaskIntoConstraints = false
        return badge
    }()

    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = L10n.generatedTranscriptsOverlayTitle
        title.numberOfLines = 0
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = titleColor
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
        description.textColor = descriptionColor
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

    private lazy var blurEffectView: BlurEffectView = {
        let blurEffectView = BlurEffectView(blurIntensity: 0.2)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        return blurEffectView
    }()

    private var gradientColor: UIColor {
        showFromEpisode ? ThemeColor.primaryUi01(): PlayerColorHelper.playerBackgroundColor01()
    }

    private var titleColor: UIColor {
        showFromEpisode ? ThemeColor.primaryText01(): .white
    }

    private var descriptionColor: UIColor {
        showFromEpisode ? ThemeColor.primaryText02(): .white.withAlphaComponent(0.5)
    }

    private var backgroundColor: UIColor {
        showFromEpisode ? ThemeColor.primaryUi01().withAlphaComponent(0.70) : PlayerColorHelper.playerBackgroundColor01().withAlphaComponent(0.45)
    }

    private var closeButtonColor: UIColor {
        showFromEpisode ? ThemeColor.primaryText01() : ThemeColor.primaryIcon02()
    }

    private lazy var topGradient: GradientView = {
        let gradientView = GradientView(firstColor: gradientColor, secondColor: gradientColor.withAlphaComponent(0))
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()

    private var showFromEpisode: Bool {
        analyticsSource == .episode
    }

    init(playbackManager: PlaybackManager, analyticsSource: AnalyticsSource = .player) {
        self.playbackManager = playbackManager
        self.analyticsSource = analyticsSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func didAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(subscriptionStatusDidChange), name: ServerNotifications.subscriptionStatusChanged, object: nil)
        track(event: .transcriptGeneratedPaywallShown)
    }

    func didDisappear() {
        NotificationCenter.default.removeObserver(self)
        track(event: .transcriptGeneratedPaywallDismissed)
    }

    private func setupView() {
        view.backgroundColor = backgroundColor

        view.addSubview(blurEffectView)
        view.addSubview(topGradient)

        view.addSubview(stackView)
        view.addSubview(badge)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(paywallButton)

        stackView.addArrangedSubview(closeButton)
        stackView.addArrangedSubview(UIView())

        let readableContentGuideMargin = 12.0
        let topMargin = showFromEpisode ? 24.0 : 0.0

        NSLayoutConstraint.activate(
            [
                blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
                blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                topGradient.topAnchor.constraint(equalTo: view.topAnchor),
                topGradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                topGradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                topGradient.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: 100.0),
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin),
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
        track(event: .transcriptGeneratedPaywallSubscribeTapped)
        if analyticsSource == .player {
            NavigationManager.sharedManager.showUpsellView(from: self, source: .generatedTranscripts)
        } else {
            let controller = OnboardingFlow.shared.begin(flow: .plusUpsell, source: PlusUpgradeViewSource.generatedTranscripts.rawValue, context: [:])
            self.parent?.present(controller, animated: true, completion: nil)
        }
    }

    @objc private func subscriptionStatusDidChange() {
        DispatchQueue.main.async { [weak self] in
            if SubscriptionHelper.hasActiveSubscription(), SyncManager.isUserLoggedIn() {
                self?.purchaseSuccessfull?()
            }
        }
    }

    private func track(event: AnalyticsEvent) {
        guard let episode = playbackManager.currentEpisode(),
              let podcast = playbackManager.currentPodcast else {
            return
        }
        Analytics.track(event, properties: ["episode_uuid": episode.uuid, "podcast_uuid": podcast.uuid, "source": analyticsSource.rawValue])
    }
}
