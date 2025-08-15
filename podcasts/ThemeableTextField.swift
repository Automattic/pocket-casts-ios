import UIKit

class ThemeableTextField: UITextField {
    var textStyle: ThemeStyle = .primaryText01 {
        didSet {
            updateColor()
        }
    }

    var backgroundStyle: ThemeStyle? {
        didSet {
            updateColor()
        }
    }

    var placeholderStyle: ThemeStyle = .primaryText02 {
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
    }

    private func updateColor() {
        textColor = AppTheme.colorForStyle(textStyle)
        if let placeholder = placeholder {
            attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(placeholderStyle).withAlphaComponent(0.5)])
        }
        if let background = backgroundStyle {
            backgroundColor = AppTheme.colorForStyle(background)
        } else {
            backgroundColor = UIColor.clear
        }

        keyboardAppearance = AppTheme.keyboardAppearance()
    }
}
