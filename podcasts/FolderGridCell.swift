import PocketCastsDataModel
import UIKit

class FolderGridCell: UICollectionViewCell {

    @IBOutlet var containerView: UIView!

    @IBOutlet var folderPreview: FolderPreviewView!

    @IBOutlet var badgeView: GridBadgeView!

    func populateFrom(folder: Folder, badgeType: BadgeType, libraryType: LibraryType) {
        folderPreview.populateFromAsync(folder: folder)

        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true

        badgeView.populateFrom(folder: folder, badgeType: badgeType, libraryType: libraryType)
    }
}
