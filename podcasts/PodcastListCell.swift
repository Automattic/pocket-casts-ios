import PocketCastsDataModel
import UIKit

class PodcastListCell: ThemeableCollectionCell {
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var podcastTitle: ThemeableLabel! {
        didSet {
            podcastTitle.font = UIFont.font(ofSize: 16, weight: .medium, scalingWith: .callout)
            podcastTitle.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var podcastInfo: ThemeableLabel! {
        didSet {
            podcastInfo.style = .primaryText02
            podcastInfo.font = UIFont.font(ofSize: 14, weight: .regular, scalingWith: .subheadline)
            podcastInfo.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var supporterHeart: PodcastHeartView!
    @IBOutlet var unplayedBadge: UnplayedBadge!
    @IBOutlet var unplayedHeight: NSLayoutConstraint!

    private var badgeType: BadgeType = .off

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isAccessibilityElement = true
    }

    func populateFrom(_ podcast: Podcast, badgeType: BadgeType) {
        self.badgeType = badgeType
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

        updateSize()
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let imageSize = max(56, metric.scaledValue(for: 56))
        updateSizeConstraints(of: podcastImage, to: imageSize)

        let badgeMetric = UIFontMetrics(forTextStyle: .footnote)
        switch badgeType {
            case .allUnplayed:
                unplayedHeight.constant = max(28, badgeMetric.scaledValue(for: 28))
            case .latestEpisode:
                unplayedHeight.constant = max(12, badgeMetric.scaledValue(for: 12))
            case .off:
                break
        }
        unplayedBadge.layoutIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory else { return }
        updateSize()
    }
}
