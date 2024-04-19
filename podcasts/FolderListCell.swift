import PocketCastsDataModel
import UIKit

class FolderListCell: ThemeableCollectionCell {
    @IBOutlet var folderPreview: FolderPreviewView! {
        didSet {
            folderPreview.showFolderName = false
        }
    }

    @IBOutlet var folderName: ThemeableLabel!
    @IBOutlet var folderInfo: ThemeableLabel! {
        didSet {
            folderInfo.style = .primaryText02
        }
    }

    @IBOutlet var unplayedBadge: UnplayedBadge!
    @IBOutlet var unplayedHeight: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        isAccessibilityElement = true
    }

    func populateFrom(folder: Folder, badgeType: BadgeType) {
        folderName.text = folder.name
        folderPreview.populateFrom(folder: folder)
        folderPreview.backgroundColor = AppTheme.folderColor(colorInt: folder.color)

        accessibilityLabel = folderPreview.accessibilityLabel

        let count = DataManager.sharedManager.countOfPodcastsInFolder(folder: folder)
        folderInfo.text = L10n.podcastCount(count)

        if badgeType == .allUnplayed {
            unplayedHeight.constant = 28
            unplayedBadge.layoutIfNeeded()

            unplayedBadge.showsNumber = true
            unplayedBadge.unplayedCount = folder.cachedUnreadCount > 99 ? 99 : folder.cachedUnreadCount
            unplayedBadge.isHidden = folder.cachedUnreadCount == 0
        } else if badgeType == .latestEpisode {
            unplayedHeight.constant = 12
            unplayedBadge.layoutIfNeeded()

            unplayedBadge.showsNumber = false
            unplayedBadge.isHidden = folder.cachedUnreadCount == 0
        } else {
            unplayedBadge.isHidden = true
        }
        unplayedBadge.updateColors()
    }
}
