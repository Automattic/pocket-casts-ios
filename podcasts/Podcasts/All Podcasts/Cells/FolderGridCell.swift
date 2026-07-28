import PocketCastsDataModel
import UIKit

class FolderGridCell: UICollectionViewCell {

    @IBOutlet var shadowView: UIView!

    @IBOutlet var containerView: UIView!

    @IBOutlet var folderPreview: FolderPreviewView!

    @IBOutlet var badgeView: GridBadgeView!

    func populateFrom(folder: Folder, badgeType: BadgeType, libraryType: LibraryType) {
        folderPreview.populateFromAsync(folder: folder)

        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true

        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
        shadowView.layer.shadowOpacity = 0.1
        shadowView.layer.shadowRadius = 2
        shadowView.layer.cornerRadius = 4

        badgeView.populateFrom(folder: folder, badgeType: badgeType)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }
}
