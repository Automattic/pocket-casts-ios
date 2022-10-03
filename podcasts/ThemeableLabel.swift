
import UIKit

class ThemeableLabel: UILabel {
    var style: ThemeStyle = .primaryText01 {
        didSet {
            updateTextColor()
        }
    }

    var themeOverride: Theme.ThemeType? {
        didSet {
            updateTextColor()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        updateTextColor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        updateTextColor()
    }

    @objc private func themeDidChange() {
        updateTextColor()
        handleThemeDidChange()
    }

    // can be overriden by sub-classes to do more when the theme changes
    func handleThemeDidChange() {}

    private func updateTextColor() {
        textColor = AppTheme.colorForStyle(style, themeOverride: themeOverride)
    }
}
