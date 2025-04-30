import UIKit

class DisclosureCell: ThemeableCell {
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellLabel: UILabel!
    @IBOutlet var disclosureImage: UIImageView!
    @IBOutlet var cellSecondaryLabel: ThemeableLabel! {
        didSet {
            cellSecondaryLabel.style = .primaryText02
        }
    }

    @IBOutlet var cellTextToImageConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        cellTextToImageConstraint.isActive = false
    }

    func setImage(imageName: String?, tintColor: UIColor? = nil) {
        if let imageName = imageName {
            cellTextToImageConstraint.isActive = true
            cellImage.tintColor = tintColor
            cellImage.image = UIImage(named: imageName)
        } else {
            cellTextToImageConstraint.isActive = false
            cellImage.image = nil
        }
    }

    override func handleThemeDidChange() {
        disclosureImage.tintColor = ThemeColor.primaryIcon02()
    }

    var isLocked = true {
        didSet {
            contentView.isUserInteractionEnabled = isLocked
            contentView.alpha = isLocked ? 1 : 0.3
        }
    }
}
