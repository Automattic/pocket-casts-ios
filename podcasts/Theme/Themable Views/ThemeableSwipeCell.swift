import SwipeCellKit
import UIKit

class ThemeableSwipeCell: SwipeTableViewCell {
    var style: ThemeStyle = .primaryUi02 {
        didSet {
            updateColor()
        }
    }

    var selectedStyle: ThemeStyle = .primaryUi02Active
    var iconStyle: ThemeStyle = .primaryIcon02
    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColor()
        }
    }

    /// Lets the table show through the row background while the cell isn't highlighted
    var isTransparent = false {
        didSet {
            guard isTransparent != oldValue else { return }
            setHighlightedState(isHighlighted || isSelected)
        }
    }

    private var restingBackgroundColor: UIColor {
        if isTransparent, style == .primaryUi02 {
            return .clear
        }
        return AppTheme.colorForStyle(style, themeOverride: themeOverride)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        updateColor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setHighlightedState(highlighted)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        setHighlightedState(selected)
    }

    @objc private func themeDidChange() {
        updateColor()
    }

    func handleThemeDidChange() {}

    func updateColor() {
        updateBgColor(restingBackgroundColor)
        accessoryView?.tintColor = AppTheme.colorForStyle(iconStyle, themeOverride: themeOverride)
        tintColor = AppTheme.colorForStyle(iconStyle, themeOverride: themeOverride)

        handleThemeDidChange()
    }

    func setHighlightedState(_ highlighted: Bool) {
        if highlighted {
            updateBgColor(AppTheme.colorForStyle(selectedStyle, themeOverride: themeOverride))
        } else {
            updateBgColor(restingBackgroundColor)
        }
    }

    private func updateBgColor(_ color: UIColor) {
        contentView.backgroundColor = color
        backgroundColor = color
        accessoryView?.backgroundColor = color
    }
}
