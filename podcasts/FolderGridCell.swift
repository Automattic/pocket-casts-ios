import PocketCastsDataModel
import UIKit

class FolderGridCell: UICollectionViewCell {
    @IBOutlet var folderPreview: FolderPreviewView!

    @IBOutlet var unplayedSashView: UnplayedSashOverlayView!

    func populateFrom(folder: Folder, badgeType: BadgeType, libraryType: LibraryType) {
        folderPreview.populateFromAsync(folder: folder)

        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true

        unplayedSashView.populateFrom(folder: folder, badgeType: badgeType, libraryType: libraryType)
    }
}
