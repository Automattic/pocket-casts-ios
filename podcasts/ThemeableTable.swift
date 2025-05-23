
import UIKit

class ThemeableTable: UITableView {
    var themeStyle: ThemeStyle = .primaryUi04 {
        didSet {
            updateColor()
        }
    }

    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColor()
        }
    }

    override init(frame: CGRect = .zero, style: UITableView.Style = .plain) {
        super.init(frame: frame, style: style)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        updateColor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func themeDidChange() {
        updateColor()
    }

    class func setHeaderFooterTextColor(on headerFooter: UIView) {
        // we do this instead of using UIAppearance because UIKit overwrites this colour sometimes
        // mentioned here (https://developer.apple.com/forums/thread/60735) and reproducible if you set your phone to dark and our app to light
        if let headerFooterView = headerFooter as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = ThemeColor.primaryText02()
        }
    }

    private func updateColor() {
        backgroundColor = AppTheme.colorForStyle(themeStyle, themeOverride: themeOverride)
        separatorColor = AppTheme.tableDividerColor(for: themeOverride)
        indicatorStyle = AppTheme.indicatorStyle()
    }
}
