import UIKit

class NothingUpNextCell: ThemeableCell {
    override var themeOverride: Theme.ThemeType? {
        didSet {
            super.updateColor()
            headingLabel.themeOverride = themeOverride
            descriptionLabel.themeOverride = themeOverride
            messageBackground.themeOverride = themeOverride
        }
    }

    @IBOutlet var messageBackground: ThemeableView! {
        didSet {
            messageBackground.style = .primaryUi06
            messageBackground.layer.cornerRadius = 8
        }
    }

    @IBOutlet var headingLabel: ThemeableLabel! {
        didSet {
            headingLabel.style = .primaryText01
            headingLabel.themeOverride = themeOverride
            headingLabel.text = L10n.upNextEmptyTitle
        }
    }

    @IBOutlet var descriptionLabel: ThemeableLabel! {
        didSet {
            descriptionLabel.style = .primaryText02
            descriptionLabel.themeOverride = themeOverride
            descriptionLabel.text = L10n.upNextEmptyDescription
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = UIColor.clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    override func setEditing(_ editing: Bool, animated: Bool) {}
}
