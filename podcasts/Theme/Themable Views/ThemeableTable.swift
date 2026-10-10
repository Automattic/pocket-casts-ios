
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

    private var separatorInsetWithoutLeftSafeArea: UIEdgeInsets?

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        guard safeAreaInsets.left > 0 || safeAreaInsets.right > 0 else {
            updateSeparatorInset(margin: 0)
            return
        }
        let minimumMargin: CGFloat = traitCollection.horizontalSizeClass == .regular ? 20 : 16
        let margin: CGFloat
        if safeAreaInsets.left == 0 {
            margin = max(layoutMargins.left, minimumMargin)
        } else if safeAreaInsets.right == 0 {
            margin = max(layoutMargins.right, minimumMargin)
        } else {
            margin = 20
        }
        let margins = NSDirectionalEdgeInsets(top: 0, leading: margin, bottom: 0, trailing: margin)
        if directionalLayoutMargins != margins {
            directionalLayoutMargins = margins
        }
        updateSeparatorInset(margin: margin)
    }

    /// System section footers start at the left separator inset rather than the margins, so with a left safe area,
    /// e.g. in the secondary column of a split view, they need it to line up with the rows.
    private func updateSeparatorInset(margin: CGFloat) {
        if safeAreaInsets.left > 0 {
            if separatorInsetWithoutLeftSafeArea == nil {
                separatorInsetWithoutLeftSafeArea = separatorInset
            }
            separatorInset.left = safeAreaInsets.left + margin
        } else if let separatorInsetWithoutLeftSafeArea {
            separatorInset = separatorInsetWithoutLeftSafeArea
            self.separatorInsetWithoutLeftSafeArea = nil
        }
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
