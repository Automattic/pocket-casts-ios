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
            podcastInfo.font = UIFont.font(ofSize: 14, weight: .regular, scalingWith: .footnote)
            podcastInfo.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var unplayedBadge: UnplayedBadge!
    @IBOutlet var unplayedHeight: NSLayoutConstraint!
    @IBOutlet var contentStackView: UIStackView!

    private var supporterHeart: PodcastHeartView?

    private var badgeType: BadgeType = .off

    private static let reorderHandleGutter: CGFloat = 40

    private var defaultContentTrailingConstant: CGFloat?
    private lazy var contentTrailingConstraint: NSLayoutConstraint? = {
        let constraint = contentView.constraints.first { c in
            c.firstAttribute == .trailing && c.secondAttribute == .trailing && (c.firstItem as? UIView) === contentView
        }
        defaultContentTrailingConstant = constraint?.constant
        return constraint
    }()

    private lazy var reorderHandle: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        view.tintColor = ThemeColor.primaryIcon02()
        view.contentMode = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            view.widthAnchor.constraint(equalToConstant: 24),
            view.heightAnchor.constraint(equalToConstant: 24)
        ])
        return view
    }()

    /// Shows a reorder grabber on the trailing edge and shifts existing content
    /// left to make room, so the handle doesn't overlay the badge/heart.
    var showsReorderHandle: Bool = false {
        didSet {
            guard showsReorderHandle != oldValue else { return }
            reorderHandle.isHidden = !showsReorderHandle
            if let constraint = contentTrailingConstraint, let base = defaultContentTrailingConstant {
                constraint.constant = base + (showsReorderHandle ? Self.reorderHandleGutter : 0)
            }
        }
    }

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

            unplayedBadge.showsNumber = true
            unplayedBadge.unplayedCount = podcast.cachedUnreadCount > 99 ? 99 : podcast.cachedUnreadCount
            unplayedBadge.isHidden = podcast.cachedUnreadCount == 0
        } else if badgeType == .latestEpisode {
            unplayedHeight.constant = 12

            unplayedBadge.showsNumber = false
            unplayedBadge.isHidden = podcast.cachedUnreadCount == 0
        } else {
            unplayedBadge.isHidden = true
        }

        unplayedBadge.updateColors()

        if podcast.isPaid {
            let heart = supporterHeart ?? makeSupporterHeart()
            heart.isHidden = false
            heart.setPodcastColor(podcast: podcast)
            heart.isShadowHidden = true
        } else {
            supporterHeart?.isHidden = true
        }

        updateSize()
    }

    private func makeSupporterHeart() -> PodcastHeartView {
        let heart = PodcastHeartView(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
        heart.translatesAutoresizingMaskIntoConstraints = false
        let unplayedIndex = contentStackView.arrangedSubviews.firstIndex(of: unplayedBadge) ?? contentStackView.arrangedSubviews.count
        contentStackView.insertArrangedSubview(heart, at: unplayedIndex)
        NSLayoutConstraint.activate([
            heart.widthAnchor.constraint(equalToConstant: 28),
            heart.widthAnchor.constraint(equalTo: heart.heightAnchor),
        ])
        supporterHeart = heart
        return heart
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let imageSize = max(56, metric.scaledValue(for: 56))
        podcastImage.updateSizeConstraints(to: imageSize)

        let badgeMetric = UIFontMetrics(forTextStyle: .largeTitle)
        switch badgeType {
            case .allUnplayed:
                unplayedHeight.constant = max(28, badgeMetric.scaledValue(for: 28))
            case .latestEpisode:
                unplayedHeight.constant = max(12, badgeMetric.scaledValue(for: 12))
            case .off:
                break
        }

        podcastTitle.updateNumberOfLines(regular: 1, accessibility: 3)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory else { return }
        updateSize()
    }
}
