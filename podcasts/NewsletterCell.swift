import UIKit

class NewsletterCell: ThemeableCell {
    @IBOutlet var cellSwitch: ThemeableSwitch!
    
    @IBOutlet var cellLabel: ThemeableLabel! {
        didSet {
            cellLabel.text = L10n.Localizable.pocketCastsNewsletter
        }
    }

    @IBOutlet var cellSecondaryLabel: ThemeableLabel! {
        didSet {
            cellSecondaryLabel.style = .primaryText02
            cellSecondaryLabel.text = L10n.Localizable.pocketCastsNewsletterDescription
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
}
