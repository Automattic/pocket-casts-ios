import PocketCastsDataModel
import UIKit

class FolderGridCell: UICollectionViewCell {

    @IBOutlet var containerView: UIView!

    @IBOutlet var simpleBadgeView: CircleView!

    @IBOutlet var folderPreview: FolderPreviewView!

    @IBOutlet var unplayedSashView: UnplayedSashOverlayView!

    func populateFrom(folder: Folder, badgeType: BadgeType, libraryType: LibraryType) {
        folderPreview.populateFrom(folder: folder)

        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true

        updateBadge(folder: folder, badgeType: badgeType, libraryType: libraryType)
        unplayedSashView.populateFrom(folder: folder, badgeType: badgeType, libraryType: libraryType)
    }

    private func updateBadge(folder: Folder, badgeType: BadgeType, libraryType: LibraryType) {
        guard folder.cachedUnreadCount > 0 else {
            simpleBadgeView.isHidden = true
            unplayedSashView.isHidden = true
            return
        }

        switch badgeType {
        case .latestEpisode:
            simpleBadgeView.isHidden = false
            unplayedSashView.isHidden = true
            simpleBadgeView.borderColor = ThemeColor.secondaryUi01()
            simpleBadgeView.centerColor = ThemeColor.primaryInteractive01()
            simpleBadgeView.backgroundColor = .clear
        case .allUnplayed:
            simpleBadgeView.isHidden = true
            unplayedSashView.isHidden = false
            unplayedSashView.populateFrom(folder: folder, badgeType: badgeType, libraryType: libraryType)
        case .off:
            simpleBadgeView.isHidden = true
            unplayedSashView.isHidden = true
        }
    }
}
