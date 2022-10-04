import UIKit

class ThemeableSwitch: UISwitch {
    var onStyle: ThemeStyle = .primaryInteractive01 {
        didSet {
            updateColors()
        }
    }

    var thumbStyle: ThemeStyle = .primaryInteractive02 {
        didSet {
            updateColors()
        }
    }

    var offStyle: ThemeStyle = .primaryInteractive03 {
        didSet {
            updateColors()
        }
    }

    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColors()
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
        layer.cornerRadius = 16
        updateColors()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc private func themeDidChange() {
        updateColors()
    }

    private func updateColors() {
        onTintColor = AppTheme.colorForStyle(onStyle, themeOverride: themeOverride)
        thumbTintColor = AppTheme.colorForStyle(thumbStyle, themeOverride: themeOverride)
        backgroundColor = AppTheme.colorForStyle(offStyle, themeOverride: themeOverride)
    }
}
