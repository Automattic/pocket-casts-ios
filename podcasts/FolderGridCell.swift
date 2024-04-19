import PocketCastsDataModel
import UIKit

class FolderGridCell: UICollectionViewCell {

    @IBOutlet var containerView: UIView!

    @IBOutlet var folderPreview: FolderPreviewView!

    @IBOutlet var unplayedSashView: UnplayedSashOverlayView!

    func populateFrom(folder: Folder, badgeType: BadgeType, libraryType: LibraryType) {
        folderPreview.populateFrom(folder: folder)

        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true

        unplayedSashView.populateFrom(folder: folder, badgeType: badgeType, libraryType: libraryType)
    }
}
