import PocketCastsDataModel
import UIKit

class PodcastListCell: ThemeableCollectionCell {
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var podcastTitle: ThemeableLabel!
    @IBOutlet var podcastInfo: ThemeableLabel! {
        didSet {
            podcastInfo.style = .primaryText02
        }
    }

    @IBOutlet var supporterHeart: PodcastHeartView!
    @IBOutlet var unplayedBadge: UnplayedBadge!
    @IBOutlet var unplayedHeight: NSLayoutConstraint!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isAccessibilityElement = true
    }

    func populateFrom(_ podcast: Podcast, badgeType: BadgeType) {
        podcastImage.setPodcast(uuid: podcast.uuid, size: .list)
        podcastTitle.text = podcast.title
        podcastInfo.text = podcast.author

        accessibilityLabel = podcast.title

        if badgeType == .allUnplayed {
            unplayedHeight.constant = 28
            unplayedBadge.layoutIfNeeded()

            unplayedBadge.showsNumber = true
            unplayedBadge.unplayedCount = podcast.cachedUnreadCount > 99 ? 99 : podcast.cachedUnreadCount
            unplayedBadge.isHidden = podcast.cachedUnreadCount == 0
        } else if badgeType == .latestEpisode {
            unplayedHeight.constant = 12
            unplayedBadge.layoutIfNeeded()

            unplayedBadge.showsNumber = false
            unplayedBadge.isHidden = podcast.cachedUnreadCount == 0
        } else {
            unplayedBadge.isHidden = true
        }
        unplayedBadge.updateColors()

        supporterHeart.isHidden = !podcast.isPaid
        if podcast.isPaid {
            supporterHeart.setPodcastColor(podcast: podcast)
            supporterHeart.isShadowHidden = true
        }
    }
}
