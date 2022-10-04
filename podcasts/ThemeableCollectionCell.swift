import UIKit

class ThemeableCollectionCell: UICollectionViewCell {
    var style: ThemeStyle = .primaryUi02 {
        didSet {
            updateColor(AppTheme.colorForStyle(style))
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        updateColor(AppTheme.colorForStyle(style))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func themeDidChange() {
        updateColor(AppTheme.colorForStyle(style))
        handleThemeDidChange()
    }

    func handleThemeDidChange() {}

    private func updateColor(_ color: UIColor) {
        contentView.backgroundColor = color
        backgroundColor = color
    }
}
