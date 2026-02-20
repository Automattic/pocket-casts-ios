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

    var onSubscribe: (() -> Void)?
    private var discoverPodcast: DiscoverPodcast?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateSize()
    }

    private func setHighlightedState(_ highlighted: Bool) {
        podcastImage.alpha = highlighted ? 0.6 : 1.0
    }

    func populateFrom(_ discoverPodcast: DiscoverPodcast, isSubscribed: Bool) {
        self.discoverPodcast = discoverPodcast
        if let title = discoverPodcast.title?.localized {
            podcastTitle.text = title
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

    override func prepareForReuse() {
        super.prepareForReuse()

        podcastImage.clearArtwork()
        subscribeButton.shouldAnimate = false
        subscribeButton.currentlyOn = false
        discoverPodcast = nil
        updateSize()
    }

    // MARK: - Dynamic Type support

    func updateSize() {
        let largeSize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        podcastTitle.numberOfLines = largeSize ? 2 : 1
        podcastAuthor.numberOfLines = largeSize ? 2 : 1
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateSize()
        }
    }
}
