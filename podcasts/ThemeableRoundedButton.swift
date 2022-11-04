import UIKit

class ThemeableRoundedButton: UIButton {
    var buttonStyle: ThemeStyle = .primaryInteractive01 {
        didSet {
            updateColor()
        }
    }

    var textStyle: ThemeStyle = .primaryUi01 {
        didSet {
            updateColor()
        }
    }

    var shouldFill = true {
        didSet {
            updateColor()
        }
    }

    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColor()
        }
    }

    @IBInspectable public var cornerRadius: CGFloat = 12 {
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

    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        updateColor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func themeDidChange() {
        updateColor()
    }

    func updateColor() {
        layer.cornerRadius = cornerRadius

        if shouldFill {
            backgroundColor = AppTheme.colorForStyle(buttonStyle, themeOverride: themeOverride)
            setTitleColor(AppTheme.colorForStyle(textStyle, themeOverride: themeOverride), for: .normal)
            layer.borderWidth = 0
        } else {
            backgroundColor = AppTheme.colorForStyle(textStyle, themeOverride: themeOverride)
            setTitleColor(AppTheme.colorForStyle(buttonStyle, themeOverride: themeOverride), for: .normal)
            layer.borderColor = AppTheme.colorForStyle(buttonStyle, themeOverride: themeOverride).cgColor
            layer.borderWidth = 2
        }
    }
}
