
import UIKit

class ThemeDividerView: UIView {
    var style: ThemeStyle = .primaryUi05 {
        didSet {
            setBgColorForTheme()
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

    var themeOverride: Theme.ThemeType? {
        didSet {
            setBgColorForTheme()
        }
    }

    private func setup() {
        setBgColorForTheme()

        NotificationCenter.default.addObserver(self, selector: #selector(ThemeDividerView.themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func themeDidChange() {
        setBgColorForTheme()
    }

    private func setBgColorForTheme() {
        backgroundColor = AppTheme.colorForStyle(style, themeOverride: themeOverride)
    }
}
