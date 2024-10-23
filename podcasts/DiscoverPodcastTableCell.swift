import PocketCastsDataModel
import PocketCastsServer
import UIKit

class DiscoverPodcastTableCell: ThemeableCell {
    @IBOutlet var podcastImage: UIImageView!
    @IBOutlet var shadowView: UIView! {
        didSet {
            shadowView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
            shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
            shadowView.layer.shadowOpacity = 0.1
            shadowView.layer.shadowRadius = 2
            shadowView.layer.cornerRadius = 5

            shadowView.layer.shadowPath = UIBezierPath(rect: shadowView.layer.bounds).cgPath
        }
    }

    @IBOutlet var podcastTitle: UILabel!
    @IBOutlet var podcastAuthor: ThemeableLabel! {
        didSet {
            podcastAuthor.style = .primaryText02
        }
    }

    @IBOutlet var itemNumber: ThemeableLabel! {
        didSet {
            itemNumber.style = .primaryText02
        }
    }

    @IBOutlet var subscribeButton: BouncyButton! {
        didSet {
            subscribeButton.onImage = UIImage(named: "discover_tick")
            subscribeButton.offImage = UIImage(named: "discover_add")
            subscribeButton.tintColor = ThemeColor.secondaryIcon01()

            subscribeButton.offAccessibilityLabel = L10n.subscribe
            subscribeButton.onAccessibilityLabel = L10n.subscribed

            NotificationCenter.default.addObserver(self, selector: #selector(podcastWasAdded), name: Constants.Notifications.podcastAdded, object: nil)
        }
    }

    @IBOutlet var numberWidth: NSLayoutConstraint!
    @IBOutlet var podcastImageLeadingConstraint: NSLayoutConstraint!

    private var discoverPodcast: DiscoverPodcast?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    var subscribeSource: AnalyticsSource?

    func populateFrom(_ discoverPodcast: DiscoverPodcast, number: Int) {
        self.discoverPodcast = discoverPodcast

        podcastTitle.text = discoverPodcast.title?.localized
        podcastAuthor.text = discoverPodcast.author
        itemNumber.text = (number > 0) ? String(number) : nil
        itemNumber.textColor = ThemeColor.primaryIcon01()
        if itemNumber.text == nil {
            numberWidth.constant = 0
            podcastImageLeadingConstraint.constant = 16
        }

        subscribeButton.currentlyOn = false
        if let uuid = discoverPodcast.uuid {
            if let _ = DataManager.sharedManager.findPodcast(uuid: uuid) {
                subscribeButton.currentlyOn = true
            }

            let imageUrl = DiscoverServerHandler.thumbnailUrlString(forPodcast: uuid, size: 140)
            ImageManager.sharedManager.loadSearchImage(imageUrl: imageUrl, imageView: podcastImage, placeholderSize: .list)
        }

        subscribeButton.shouldAnimate = true
    }

    @objc private func podcastWasAdded() {
        if let headerUuid = discoverPodcast?.uuid {
            if let _ = DataManager.sharedManager.findPodcast(uuid: headerUuid) {
                if !subscribeButton.currentlyOn { subscribeButton.currentlyOn = true }
            } else {
                if subscribeButton.currentlyOn { subscribeButton.currentlyOn = false }
            }
        }
    }

    @IBAction func subscribeTapped(_ sender: AnyObject) {
        subscribeButton.currentlyOn = true

        guard let discoverPodcast = discoverPodcast else { return }

        if discoverPodcast.iTunesOnly() {
            ServerPodcastManager.shared.subscribeFromItunesId(Int(discoverPodcast.iTunesId!)!, completion: nil)
        } else if let uuid = discoverPodcast.uuid {
            ServerPodcastManager.shared.subscribe(to: uuid, completion: nil)
        }

        let uuid = discoverPodcast.uuid ?? discoverPodcast.iTunesId ?? "unknown"
        Analytics.track(.podcastSubscribed, properties: ["source": subscribeSource ?? "unknown", "uuid": uuid])
    }

    override func handleThemeDidChange() {
        subscribeButton.tintColor = ThemeColor.primaryIcon02()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        ImageManager.sharedManager.cancelLoad(podcastImage)

        subscribeButton.shouldAnimate = false
        discoverPodcast = nil
    }
}
