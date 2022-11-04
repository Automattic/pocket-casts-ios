import UIKit

class SocialLoginButton: ThemeableRoundedButton {
    private let icon: UIImage?
    private let darkIcon: UIImage?

    init(iconName: String,
         darkIconName: String? = nil,
         title: String,
         borderStyle: ThemeStyle = .primaryInteractive03,
         textStyle: ThemeStyle = .primaryText01,
         font: UIFont = .systemFont(ofSize: 18, weight: .semibold)) {
        self.icon = UIImage(named: iconName)
        self.darkIcon = UIImage(named: darkIconName ?? iconName)

        super.init(frame: .zero)

        self.textStyle = textStyle
        buttonStyle = borderStyle

        updateIconForTheme()
        setTitle(title, for: .normal)
        titleLabel?.font = font
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        alignImageView()
    }

    override func themeDidChange() {
        super.themeDidChange()

        updateIconForTheme()
    }

    override func updateColor() {
        layer.cornerRadius = cornerRadius

        backgroundColor = .clear
        setTitleColor(AppTheme.colorForStyle(textStyle, themeOverride: themeOverride), for: .normal)
        layer.borderColor = AppTheme.colorForStyle(buttonStyle, themeOverride: themeOverride).cgColor
        layer.borderWidth = Config.borderWidth
    }

    private func alignImageView() {
        guard let imageView else { return }

        // Left align the image view for LTR languages
        if effectiveUserInterfaceLayoutDirection == .leftToRight {
            imageView.frame.origin.x = bounds.minX + Config.imageLeftMargin
            return
        }

        // Right align the image view for RTL languages
        let width = imageView.frame.width
        imageView.frame.origin.x = bounds.maxX - width - Config.imageLeftMargin
    }

    private func updateIconForTheme() {
        let iconImage = Theme.isDarkTheme() ? darkIcon : icon
        setImage(iconImage, for: .normal)
    }

    private enum Config {
        static let imageLeftMargin = 20.0
        static let borderWidth = 2.0
    }
}
