import UIKit

class NewsletterCell: ThemeableCell {
    @IBOutlet var cellSwitch: ThemeableSwitch!

    @IBOutlet var cellLabel: ThemeableLabel! {
        didSet {
            cellLabel.text = L10n.pocketCastsNewsletter
            cellLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
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

        updateSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }

    func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let iconSize = max(24, metric.scaledValue(for: 24))
        cellImage.updateSizeConstraints(to: iconSize)
    }
}
