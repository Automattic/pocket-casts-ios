
import UIKit

class ThemeableUIButton: UIButton {
    var style: ThemeStyle = .primaryInteractive01 {
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

    override func awakeFromNib() {
        super.awakeFromNib()

        updateColors()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        updateColors()
    }

    @objc private func themeDidChange() {
        updateColors()
        handleThemeDidChange()
    }

    // can be overriden by sub-classes to do more when the theme changes
    func handleThemeDidChange() {}

    private func updateColors() {
        let color = AppTheme.colorForStyle(style)

        // we use both these methods because setTitleColor seems to work for the initial state and changing the label for changes from then on
        setTitleColor(color, for: .normal)
        titleLabel?.textColor = color

        imageView?.tintColor = color
    }
}
