import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class PodcastGroupCell: ThemeableCell {
    @IBOutlet var podcastImage: UIImageView! {
        didSet {
            podcastImage.layer.cornerRadius = 4
        }
    }

    @IBOutlet var podcastName: UILabel!
    @IBOutlet var podcastDescription: ThemeableLabel! {
        didSet {
            podcastDescription.style = .primaryText02
        }
    }

    @IBOutlet var subscribeButton: BouncyButton! {
        didSet {
            subscribeButton.onImage = UIImage(named: "discover_tick")
            subscribeButton.offImage = UIImage(named: "discover_add")
            subscribeButton.offAccessibilityLabel = FeatureFlag.useFollowNaming.enabled ? L10n.follow : L10n.subscribe
            subscribeButton.onAccessibilityLabel = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.subscribed

            subscribeButton.tintColor = ThemeColor.secondaryIcon01()
        }
    }

    @IBOutlet var shadowView: UIView! {
        didSet {
            shadowView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
            shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
            shadowView.layer.shadowOpacity = 0.1
            shadowView.layer.shadowRadius = 2
            shadowView.layer.cornerRadius = 4

            shadowView.layer.shadowPath = UIBezierPath(rect: shadowView.layer.bounds).cgPath
        }
    }

    @IBAction func subscribeTapped(_ sender: UIButton) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.subscribeRequestedFromCell, object: self)
        subscribeButton.currentlyOn = true
    }

    func populateFrom(_ podcast: DiscoverPodcast) {
        podcastName.text = podcast.title?.localized
        podcastDescription.text = podcast.shortDescription
        subscribeButton.currentlyOn = false
        if let uuid = podcast.uuid, let _ = DataManager.sharedManager.findPodcast(uuid: uuid) {
            subscribeButton.currentlyOn = true
        }
        subscribeButton.shouldAnimate = true

        if let uuid = podcast.uuid {
            ImageManager.sharedManager.loadImage(podcastUuid: uuid, imageView: podcastImage, size: .list, showPlaceHolder: true)
        }
    }

    override func handleThemeDidChange() {
        subscribeButton.tintColor = ThemeColor.secondaryIcon01()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        ImageManager.sharedManager.cancelLoad(podcastImage)
        subscribeButton.shouldAnimate = false
    }
}
