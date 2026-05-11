import PocketCastsDataModel
import UIKit

class FolderListCell: ThemeableCollectionCell {
    @IBOutlet var folderPreview: FolderPreviewView! {
        didSet {
            folderPreview.showFolderName = false
        }
    }

    @IBOutlet var folderName: ThemeableLabel! {
        didSet {
            folderName.font = UIFont.font(ofSize: 16, weight: .medium, scalingWith: .callout)
            folderName.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var folderInfo: ThemeableLabel! {
        didSet {
            folderInfo.style = .primaryText02
            folderInfo.font = UIFont.font(ofSize: 14, weight: .regular, scalingWith: .footnote)
            folderInfo.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var unplayedBadge: UnplayedBadge!
    @IBOutlet var unplayedHeight: NSLayoutConstraint!

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
    /// left to make room, so the handle doesn't overlay the badge.
    var showsReorderHandle: Bool = false {
        didSet {
            guard showsReorderHandle != oldValue else { return }
            reorderHandle.isHidden = !showsReorderHandle
            if let constraint = contentTrailingConstraint, let base = defaultContentTrailingConstant {
                constraint.constant = base + (showsReorderHandle ? Self.reorderHandleGutter : 0)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        isAccessibilityElement = true
        updateSize()
    }

    func populateFrom(folder: Folder, badgeType: BadgeType) {
        self.badgeType = badgeType
        folderName.text = folder.name
        folderPreview.populateFromAsync(folder: folder)
        folderPreview.backgroundColor = AppTheme.folderColor(colorInt: folder.color)

        accessibilityLabel = folderPreview.accessibilityLabel

        let count = DataManager.sharedManager.countOfPodcastsInFolder(folder: folder)
        folderInfo.text = L10n.podcastCount(count)

        if badgeType == .allUnplayed {
            let metric = UIFontMetrics(forTextStyle: .largeTitle)
            unplayedHeight.constant = max(28, metric.scaledValue(for: 28))
            unplayedBadge.layoutIfNeeded()

            unplayedBadge.showsNumber = true
            unplayedBadge.unplayedCount = folder.cachedUnreadCount > 99 ? 99 : folder.cachedUnreadCount
            unplayedBadge.isHidden = folder.cachedUnreadCount == 0
        } else if badgeType == .latestEpisode {
            let metric = UIFontMetrics(forTextStyle: .largeTitle)
            unplayedHeight.constant = max(12, metric.scaledValue(for: 12))
            unplayedBadge.layoutIfNeeded()

            unplayedBadge.showsNumber = false
            unplayedBadge.isHidden = folder.cachedUnreadCount == 0
        } else {
            unplayedBadge.isHidden = true
        }

        unplayedBadge.updateColors()
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let imageSize = max(56, metric.scaledValue(for: 56))
        folderPreview.updateSizeConstraints(to: imageSize)

        let badgeMetric = UIFontMetrics(forTextStyle: .largeTitle)
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
