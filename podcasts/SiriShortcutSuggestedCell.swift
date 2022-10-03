import UIKit

class SiriShortcutSuggestedCell: ThemeableCell {
    @IBOutlet var addIcon: TintableImageView! {
        didSet {
            addIcon.tintColor = ThemeColor.primaryInteractive01()
        }
    }

    @IBOutlet var titleLabel: UILabel!
}
