import UIKit

class FilterNameCell: ThemeableCell {
    static let cellHeight = 72.0

    @IBOutlet var filterImage: UIImageView!
    @IBOutlet var filterName: ThemeableLabel!
    @IBOutlet var episodeCount: UILabel!

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
}
