import PocketCastsDataModel
import UIKit

class PodcastGridCell: UICollectionViewCell {

    @IBOutlet var containerView: UIView!
    @IBOutlet var podcastImage: UIImageView!
    @IBOutlet var podcastName: UILabel!

    @IBOutlet var badgeView: GridBadgeView!
    @IBOutlet var supporterHeart: PodcastHeartView!

    private var podcastUuid: String?
    private var badgeType = BadgeType.off

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        NotificationCenter.default.addObserver(self, selector: #selector(podcastColorsLoaded(_:)), name: Constants.Notifications.podcastColorsDownloaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(podcastImageCacheCleared), name: Constants.Notifications.podcastImageReCacheRequired, object: nil)
    }

    func populateFrom(podcast: Podcast, badgeType: BadgeType, libraryType: LibraryType) {
        self.badgeType = badgeType
        podcastUuid = podcast.uuid

        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true

        setImage()
        setColors(podcast: podcast)

        podcastName.accessibilityLabel = podcast.title

        updateBadge(podcast: podcast, badgeType: badgeType, libraryType: libraryType)

        supporterHeart.isHidden = !podcast.isPaid
        if podcast.isPaid {
            supporterHeart.setPodcastColor(podcast: podcast)
        }
    }

    @objc private func podcastImageCacheCleared() {
        setImage()
    }

    @objc private func podcastColorsLoaded(_ notification: Notification) {
        guard let uuidLoaded = notification.object as? String else { return }

        if uuidLoaded == podcastUuid, let podcast = DataManager.sharedManager.findPodcast(uuid: uuidLoaded) {
            setColors(podcast: podcast)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        podcastUuid = nil
    }

    private func setImage() {
        guard let podcastUuid = podcastUuid else { return }

        ImageManager.sharedManager.loadImage(podcastUuid: podcastUuid, imageView: podcastImage, size: .grid, showPlaceHolder: false)
    }

    private func setColors(podcast: Podcast) {
        podcastName.text = podcast.title
        let bgColor = ColorManager.backgroundColorForPodcast(podcast)
        backgroundColor = .clear
        containerView.backgroundColor = bgColor
        podcastName.backgroundColor = bgColor

        if podcast.isPaid {
            supporterHeart.setPodcastColor(podcast: podcast)
        }
    }

    private func updateBadge(podcast: Podcast, badgeType: BadgeType, libraryType: LibraryType) {
        guard podcast.cachedUnreadCount > 0 else {
            badgeView.isHidden = true
            return
        }

        badgeView.populateFrom(podcast: podcast, badgeType: badgeType, libraryType: libraryType)
    }
}
