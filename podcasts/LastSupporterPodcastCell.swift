import UIKit

class LastSupporterPodcastCell: ThemeableCell {
    @IBOutlet var yieldImage: UIImageView! {
        didSet {
            yieldImage.tintColor = AppTheme.colorForStyle(.primaryUi05Selected)
        }
    }

    @IBOutlet var borderView: ThemeableView! {
        didSet {
            borderView.style = .primaryUi06
            borderView.layer.cornerRadius = 8
            borderView.layer.borderWidth = 1
            borderView.layer.borderColor = AppTheme.colorForStyle(.primaryUi05).cgColor
        }
    }

    @IBOutlet var descriptionLabel: ThemeableLabel! {
        didSet {
            descriptionLabel.style = .primaryText02
        }
    }

    override func handleThemeDidChange() {
        yieldImage.tintColor = ThemeColor.primaryUi05Selected()
        borderView.layer.borderColor = ThemeColor.primaryUi05().cgColor
    }
}
