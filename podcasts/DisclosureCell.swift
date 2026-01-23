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
        updateDisclosureScale()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateDisclosureScale()
        }
    }

    private func updateDisclosureScale() {
        let category = UIApplication.shared.preferredContentSizeCategory
        let scale = ScaleFactorModifier.scaleFactor(for: category)
        disclosureImage.transform = CGAffineTransform(scaleX: scale, y: scale)
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
