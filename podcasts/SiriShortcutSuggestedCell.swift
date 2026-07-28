import UIKit

class SiriShortcutSuggestedCell: ThemeableCell {
    @IBOutlet var addIcon: TintableImageView! {
        didSet {
            addIcon.tintColor = ThemeColor.primaryInteractive01()
            updateSize()
        }
    }

    @IBOutlet var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: SiriShortcutSuggestedCell, _) in
            view.updateSize()
        }
    }

    private func updateSize() {
        let iconMetric = UIFontMetrics(forTextStyle: .largeTitle)
        let iconSize = max(24, iconMetric.scaledValue(for: 24))
        addIcon.updateSizeConstraints(to: iconSize)
    }
}
