import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class LargeListCell: ThemeableCollectionCell {

    @IBOutlet var podcastImage: PodcastImageView!

    @IBOutlet var podcastTitle: ThemeableLabel! {
        didSet {
            podcastTitle.font = .font(ofSize: 16, weight: .regular, scalingWith: .callout)
        }
    }
    @IBOutlet var podcastAuthor: ThemeableLabel! {
        didSet {
            podcastAuthor.style = .primaryText02
            podcastAuthor.font = .font(ofSize: 15, weight: .regular, scalingWith: .subheadline)
        }
    }

    @IBOutlet var subscribeButton: BouncyButton! {
        didSet {
            subscribeButton.onImage = UIImage(named: "discover_subscribed_dark")
            subscribeButton.offImage = UIImage(named: "discover_subscribe_dark")
            subscribeButton.tintColor = ThemeColor.contrast01()
            subscribeButton.backgroundColor = ThemeColor.veil()

            subscribeButton.offAccessibilityLabel = FeatureFlag.useFollowNaming.enabled ? L10n.follow : L10n.subscribe
            subscribeButton.onAccessibilityLabel = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.subscribed
        }
    }

    override var isSelected: Bool {
        didSet {
            setHighlightedState(isSelected)
        }
    }

    override var isHighlighted: Bool {
        didSet {
            setHighlightedState(isHighlighted)
        }
    }

    private lazy var explicitBadgeView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center
        imageView.isHidden = true
        return imageView
    }()

    var onSubscribe: (() -> Void)?
    private var discoverPodcast: DiscoverPodcast?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupExplicitBadge()
        updateSize()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: LargeListCell, _) in
            view.updateSize()
        }
    }

    private func setupExplicitBadge() {
        guard let verticalStack = podcastTitle.superview as? UIStackView else { return }

        let titleRow = UIStackView(arrangedSubviews: [podcastTitle, explicitBadgeView])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 4
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        verticalStack.insertArrangedSubview(titleRow, at: 0)

        let size = ExplicitBadgeHelper.badgeSize
        NSLayoutConstraint.activate([
            explicitBadgeView.widthAnchor.constraint(equalToConstant: size),
            explicitBadgeView.heightAnchor.constraint(equalToConstant: size),
        ])
        podcastTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        explicitBadgeView.setContentCompressionResistancePriority(.required, for: .horizontal)
        explicitBadgeView.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func setHighlightedState(_ highlighted: Bool) {
        podcastImage.alpha = highlighted ? 0.6 : 1.0
    }

    func populateFrom(_ discoverPodcast: DiscoverPodcast, isSubscribed: Bool) {
        self.discoverPodcast = discoverPodcast
        if let title = discoverPodcast.title?.localized {
            podcastTitle.text = title
            let isExplicit = FeatureFlag.showExplicitBadges.enabled && (discoverPodcast.isExplicit ?? false)
            explicitBadgeView.isHidden = !isExplicit
            if isExplicit {
                explicitBadgeView.image = ExplicitBadgeHelper.badgeImage()
            }
        }
        if let author = discoverPodcast.author {
            podcastAuthor.text = author
        }
        if let uuid = discoverPodcast.uuid {
            podcastImage.setPodcast(uuid: uuid, size: .grid)
        }
        subscribeButton.currentlyOn = isSubscribed
        subscribeButton.tintColor = ThemeColor.contrast01()
        subscribeButton.backgroundColor = ThemeColor.veil()

        subscribeButton.shouldAnimate = true
    }

    @IBAction func subscribeTapped(_ sender: AnyObject) {
        if !subscribeButton.currentlyOn {
            subscribeButton.currentlyOn = true
            onSubscribe?()
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.subscribeRequestedFromCell, object: self)
        }
    }

    override func handleThemeDidChange() {
        if !explicitBadgeView.isHidden {
            explicitBadgeView.image = ExplicitBadgeHelper.badgeImage()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        podcastImage.clearArtwork()
        subscribeButton.shouldAnimate = false
        subscribeButton.currentlyOn = false
        explicitBadgeView.isHidden = true
        discoverPodcast = nil
        updateSize()
    }

    // MARK: - Dynamic Type support

    func updateSize() {
        podcastTitle.updateNumberOfLines(regular: 1, accessibility: 2)
        podcastAuthor.updateNumberOfLines(regular: 1, accessibility: 2)
    }
}
