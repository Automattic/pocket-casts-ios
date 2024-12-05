import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class SmallListCell: ThemeableCollectionCell {
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var subscribeButton: BouncyButton! {
        didSet {
            subscribeButton.onImage = UIImage(named: "discover_tick")?.tintedImage(ThemeColor.support02())
            subscribeButton.offImage = UIImage(named: "discover_add")?.tintedImage(ThemeColor.primaryIcon02())

            subscribeButton.offAccessibilityLabel = FeatureFlag.useFollowNaming.enabled ? L10n.follow : L10n.subscribe
            subscribeButton.onAccessibilityLabel = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.subscribed
        }
    }

    @IBOutlet var podcastTitle: ThemeableLabel!
    @IBOutlet var podcastAuthor: ThemeableLabel! {
        didSet {
            podcastAuthor.style = .primaryText02
        }
    }

    var onSubscribe: (() -> Void)?
    private var discoverPodcast: DiscoverPodcast?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var isHighlighted: Bool {
        didSet {
            setSelectedState(isHighlighted)
        }
    }

    func setSelectedState(_ selected: Bool) {
        podcastImage.alpha = selected ? 0.6 : 1.0
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

        subscribeButton.shouldAnimate = true
    }

    @IBAction func subscribeTapped(_ sender: AnyObject) {
        if !subscribeButton.currentlyOn {
            subscribeButton.currentlyOn = true
            onSubscribe?()
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.subscribeRequestedFromCell, object: self)
        }
    }

    func populateFrom(_ info: DiscoverPodcast) {
        discoverPodcast = info
        podcastImage.accessibilityLabel = discoverPodcast?.title?.localized
        if let headerUuid = info.uuid {
            if let _ = DataManager.sharedManager.findPodcast(uuid: headerUuid) {
                subscribeButton.currentlyOn = true
            } else {
                subscribeButton.currentlyOn = false
            }
            subscribeButton.shouldAnimate = true

            if let title = discoverPodcast?.title?.localized {
                podcastTitle.text = title
            }
            if let author = discoverPodcast?.author {
                podcastAuthor.text = author
            }

            if let uuid = discoverPodcast?.uuid {
                podcastImage.setPodcast(uuid: uuid, size: .grid)
            }
        }
    }

    override func handleThemeDidChange() {
        subscribeButton.tintColor = ThemeColor.primaryIcon02()
        subscribeButton.onImage = UIImage(named: "discover_tick")?.tintedImage(ThemeColor.support02())
        subscribeButton.offImage = UIImage(named: "discover_add")?.tintedImage(ThemeColor.primaryIcon02())
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        podcastImage.clearArtwork()
        subscribeButton.shouldAnimate = false
        discoverPodcast = nil
        setSelectedState(false)
        subscribeButton.currentlyOn = false
    }
}
