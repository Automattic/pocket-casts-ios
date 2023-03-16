import PocketCastsDataModel
import PocketCastsServer
import UIKit

class DiscoverFeaturedView: ThemeableView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var listType: RoundedLabel! {
        didSet {
            listType.style = .contrast02
        }
    }

    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var podcastTitle: ThemeableLabel! {
        didSet {
            podcastTitle.style = .contrast01
        }
    }

    @IBOutlet var podcastAuthor: ThemeableLabel! {
        didSet {
            podcastAuthor.style = .contrast03
        }
    }

    @IBOutlet var rankingLabel: UILabel!
    @IBOutlet var podcastImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var subscribeButton: BouncyButton! {
        didSet {
            subscribeButton.onImage = UIImage(named: "discover_tick")
            subscribeButton.offImage = UIImage(named: "discover_add")
            subscribeButton.tintColor = ThemeColor.contrast02()

            subscribeButton.offAccessibilityLabel = L10n.subscribe
            subscribeButton.onAccessibilityLabel = L10n.subscribed
        }
    }

    var onSubscribe: (() -> Void)?
    private var discoverPodcast: DiscoverPodcast?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("DiscoverFeaturedView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        backgroundView.backgroundColor = AppTheme.defaultPodcastBackgroundColor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setSelectedState(_ selected: Bool) {
        podcastImage.alpha = selected ? 0.6 : 1.0
    }

    func populateFrom(_ discoverPodcast: DiscoverPodcast, isSubscribed: Bool, listName: String, isSponsored: Bool) {
        self.discoverPodcast = discoverPodcast
        listType.text = isSponsored ? L10n.discoverSponsored : listName.uppercased()
        listType.setLetterSpacing(1.57)

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

    func populateFrom(_ discoverPodcast: DiscoverPodcast, listName: String) {
        self.discoverPodcast = discoverPodcast
        listType.text = listName.uppercased()

        if let title = discoverPodcast.title?.localized {
            podcastTitle.text = title
        }

        if let author = discoverPodcast.author {
            podcastAuthor.text = author
        }

        if let uuid = discoverPodcast.uuid {
            podcastImage.setPodcast(uuid: uuid, size: .grid)
        }
        subscribeButton.currentlyOn = false
        if let uuid = discoverPodcast.uuid {
            if let _ = DataManager.sharedManager.findPodcast(uuid: uuid) {
                subscribeButton.currentlyOn = true
            }
        }

        subscribeButton.shouldAnimate = true
    }

    func showRanking() {
        rankingLabel.isHidden = false
        podcastImageLeadingConstraint.constant = 30
        layoutIfNeeded()
    }

    func setPodcastColor(_ color: UIColor) {
        let bgColor = ThemeColor.podcastUi03(podcastColor: color)
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) { [weak self] in
            self?.backgroundView.backgroundColor = bgColor
        }
    }

    @IBAction func subscribeTapped(_ sender: AnyObject) {
        if !subscribeButton.currentlyOn {
            subscribeButton.currentlyOn = true
            onSubscribe?()
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.subscribeRequestedFromCell, object: self)
        }
    }

    func clearView() {
        podcastImage.clearArtwork()
        subscribeButton.shouldAnimate = false
        discoverPodcast = nil
    }
}
