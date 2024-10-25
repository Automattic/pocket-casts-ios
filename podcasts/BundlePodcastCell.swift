import PocketCastsDataModel
import PocketCastsServer
import UIKit

class BundlePodcastCell: ThemeableCell {
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

    @IBOutlet var subscribeButton: BouncyButton! {
        didSet {
            subscribeButton.onImage = UIImage(named: "discover_tick")?.tintedImage(ThemeColor.support02())
            subscribeButton.offImage = UIImage(named: "discover_add")?.tintedImage(ThemeColor.primaryIcon02())

            subscribeButton.offAccessibilityLabel = L10n.subscribe
            subscribeButton.onAccessibilityLabel = L10n.subscribed

            NotificationCenter.default.addObserver(self, selector: #selector(podcastWasAdded), name: Constants.Notifications.podcastAdded, object: nil)
        }
    }

    @IBOutlet var disclosureImage: UIImageView! {
        didSet {
            disclosureImage.tintColor = ThemeColor.primaryIcon02()
        }
    }

    private var discoverPodcast: DiscoverPodcast?
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func populateFrom(_ discoverPodcast: DiscoverPodcast, showDisclosure: Bool = false) {
        self.discoverPodcast = discoverPodcast

        podcastTitle.text = discoverPodcast.title?.localized
        podcastAuthor.text = discoverPodcast.author

        subscribeButton.currentlyOn = false
        if let uuid = discoverPodcast.uuid {
            if showDisclosure {
                disclosureImage.isHidden = false
                subscribeButton.isHidden = true
            } else {
                disclosureImage.isHidden = true
                if let _ = DataManager.sharedManager.findPodcast(uuid: uuid) {
                    subscribeButton.currentlyOn = true
                }
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
