import UIKit

class MultiSelectActionCell: ThemeableCell {
    @IBOutlet var nameLabel: ThemeableLabel!
    @IBOutlet var iconView: UIImageView! {
        didSet {
            iconView.tintColor = AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        ensureCorrectReorderColor()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        ensureCorrectReorderColor()
    }

    private func ensureCorrectReorderColor() {
        let theme = themeOverride ?? Theme.sharedTheme.activeTheme

        overrideUserInterfaceStyle = theme.isDark ? .dark : .light
    }

    override func handleThemeDidChange() {
        nameLabel.themeOverride = themeOverride
        iconView.tintColor = AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride)
        ensureCorrectReorderColor()
    }
}
