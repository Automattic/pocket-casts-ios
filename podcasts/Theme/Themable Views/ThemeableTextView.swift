import UIKit

class ThemeableTextView: UITextView {
    var textStyle: ThemeStyle = .primaryText01 {
        didSet {
            updateColor()
        }
    }

    var backgroundStyle: ThemeStyle = .primaryUi01 {
        didSet {
            updateColor()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

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
        backgroundColor = AppTheme.colorForStyle(backgroundStyle)
    }
}
