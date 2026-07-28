import UIKit

class ThemeAwareScrollView: UIScrollView {
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
        indicatorStyle = AppTheme.indicatorStyle()
    }
}
