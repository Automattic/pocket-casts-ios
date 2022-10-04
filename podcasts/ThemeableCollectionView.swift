
import UIKit

class ThemeableCollectionView: UICollectionView {
    var style: ThemeStyle = .primaryUi04 {
        didSet {
            updateColor()
        }
    }

    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        updateColor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func themeDidChange() {
        updateColor()
    }

    private func updateColor() {
        backgroundColor = AppTheme.colorForStyle(style)
        indicatorStyle = AppTheme.indicatorStyle()
    }
}
