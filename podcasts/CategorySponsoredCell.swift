import PocketCastsDataModel
import PocketCastsServer
import UIKit

class CategorySponsoredCell: ThemeableCell {
    @IBOutlet var podcastImage: UIImageView! {
        didSet {
            podcastImage.layer.cornerRadius = 4
        }
    }

    @IBOutlet var shadowView: UIView! {
        didSet {
            shadowView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
            shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
            shadowView.layer.shadowOpacity = 0.1
            shadowView.layer.shadowRadius = 3
            shadowView.layer.cornerRadius = 4

            shadowView.layer.shadowPath = UIBezierPath(rect: shadowView.layer.bounds).cgPath
        }
    }

    @IBOutlet var sponsoredLabel: ThemeableLabel! {
        didSet {
            sponsoredLabel.style = .primaryText02
        }
    }

    @IBOutlet var podcastTitle: ThemeableLabel!
    @IBOutlet var descriptionLabel: ThemeableLabel! {
        didSet {
            descriptionLabel.style = .primaryText02
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

    private var discoverPromotion: DiscoverCategoryPromotion?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func populateFrom(_ discoverPromotion: DiscoverCategoryPromotion, isSubscribed: Bool) {
        self.discoverPromotion = discoverPromotion

        podcastTitle.text = discoverPromotion.title
        descriptionLabel.text = discoverPromotion.description
        descriptionLabel.setLineSpacing(lineSpacing: 1, lineHeightMultiple: 1.2)
        descriptionLabel.sizeToFit()

        if let uuid = discoverPromotion.podcast_uuid {
            if let _ = DataManager.sharedManager.findPodcast(uuid: uuid) {
                subscribeButton.currentlyOn = true
            }
            let imageUrl = DiscoverServerHandler.thumbnailUrlString(forPodcast: uuid, size: 140)
            ImageManager.sharedManager.loadSearchImage(imageUrl: imageUrl, imageView: podcastImage, placeholderSize: .list)
        }
        subscribeButton.currentlyOn = isSubscribed
        subscribeButton.shouldAnimate = true
    }

    @objc private func podcastWasAdded() {
        if let podcastUuid = discoverPromotion?.podcast_uuid {
            if let _ = DataManager.sharedManager.findPodcast(uuid: podcastUuid) {
                if !subscribeButton.currentlyOn { subscribeButton.currentlyOn = true }
            } else {
                if subscribeButton.currentlyOn { subscribeButton.currentlyOn = false }
            }
        }
    }

    @IBAction func subscribeTapped(_ sender: AnyObject) {
        subscribeButton.currentlyOn = true

        guard let discoverPromotion = discoverPromotion else { return }

        if let uuid = discoverPromotion.podcast_uuid {
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
        discoverPromotion = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        style = .primaryUi06
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
