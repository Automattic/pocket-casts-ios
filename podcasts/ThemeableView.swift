import UIKit

class ThemeableView: UIView {
    var style: ThemeStyle = .primaryUi01 {
        didSet {
            updateColor()
        }
    }

    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColor()
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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        updateColor()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc private func themeDidChange() {
        updateColor()
        handleThemeDidChange()
    }

    // For subclasses to be notified about theme changes
    func handleThemeDidChange() {}

    private func updateColor() {
        backgroundColor = AppTheme.colorForStyle(style, themeOverride: themeOverride)
    }
}
