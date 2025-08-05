import UIKit

class NewsletterCell: ThemeableCell {
    @IBOutlet var cellSwitch: ThemeableSwitch!

    @IBOutlet var cellLabel: ThemeableLabel! {
        didSet {
            cellLabel.text = L10n.pocketCastsNewsletter
            cellLabel.font = UIFont.font(ofSize: 15.0, weight: .medium, scalingWith: .body)
        }
    }

    @IBOutlet var cellSecondaryLabel: ThemeableLabel! {
        didSet {
            cellSecondaryLabel.style = .primaryText02
            cellSecondaryLabel.text = L10n.pocketCastsNewsletterDescription
            cellSecondaryLabel.font = UIFont.font(ofSize: 12.0, weight: .regular, scalingWith: .footnote)
        }
    }

    @IBOutlet var cellImage: UIImageView! {
        didSet {
            cellImage.tintColor = AppTheme.colorForStyle(iconStyle)
        }
    }

    override var iconStyle: ThemeStyle {
        didSet {
            handleThemeDidChange()
        }
    }

    override func handleThemeDidChange() {
        cellImage.tintColor = AppTheme.colorForStyle(iconStyle)
        cellSecondaryLabel.style = .primaryText02
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        updateImageScale()
    }

    func updateImageScale() {
        let category = UIApplication.shared.preferredContentSizeCategory
        let scale = ScaleFactorModifier.scaleFactor(for: category)

        cellImage.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}
