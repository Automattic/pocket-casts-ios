import UIKit

class ThemeableSelectionView: UIView {
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

    var isSelected: Bool = false {
        didSet {
            updateColor()
            updateAccessibilityLabel()
        }
    }

    var selectedStyle: ThemeStyle = .primaryField03Active {
        didSet {
            updateColor()
        }
    }

    var unselectedStyle: ThemeStyle = .primaryField03 {
        didSet {
            updateColor()
        }
    }

    private var unselectedAccessibilityLabel: String?

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
        backgroundColor = AppTheme.colorForStyle(style, themeOverride: themeOverride)
        layer.borderColor = isSelected ? AppTheme.colorForStyle(selectedStyle, themeOverride: themeOverride).cgColor : AppTheme.colorForStyle(unselectedStyle, themeOverride: themeOverride).cgColor
    }

    private func updateAccessibilityLabel() {
        if unselectedAccessibilityLabel == nil {
            unselectedAccessibilityLabel = accessibilityLabel
        }
        let unselectedAccessibilityLabel = self.unselectedAccessibilityLabel ?? ""
        let selectedAccessibilityLabel = "\(L10n.statusSelected), \(unselectedAccessibilityLabel)"
        accessibilityLabel = isSelected ? selectedAccessibilityLabel : unselectedAccessibilityLabel
    }
}
