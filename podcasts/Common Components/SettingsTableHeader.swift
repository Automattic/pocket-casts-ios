import UIKit

class SettingsTableHeader: ThemeableView {
    var titleLabel = ThemeableLabel()
    var clearBackground = false {
        didSet {
            handleThemeDidChange()
        }
    }

    init(frame: CGRect, title: String, showLockedImage: Bool = false, lockedSelector: Selector? = nil, target: Any? = nil, themeStyle: ThemeStyle = .primaryUi04, themeOverride: Theme.ThemeType? = nil) {
        super.init(frame: frame)
        self.themeOverride = themeOverride
        setupView(title: title, showLockedImage: showLockedImage, lockedSelector: lockedSelector, lockedTarget: target, themeStyle: themeStyle)
    }

    init(frame: CGRect, title: String, rightBtnTitle: String, rightBtnSelector: Selector? = nil, rightBtnTarget: Any? = nil, rightBtnThemeStyle: ThemeStyle = .primaryInteractive01, themeStyle: ThemeStyle = .primaryUi04, themeOverride: Theme.ThemeType? = nil) {
        super.init(frame: frame)
        self.themeOverride = themeOverride
        setupView(title: title, rightBtnTitle: rightBtnTitle, rightBtnSelector: rightBtnSelector, rightBtnTarget: rightBtnTarget, rightBtnThemeStyle: rightBtnThemeStyle, themeStyle: themeStyle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var lockImage: UIView?

    private func setupView(title: String, showLockedImage: Bool = false, lockedSelector: Selector? = nil, lockedTarget: Any? = nil, rightBtnTitle: String? = nil, rightBtnSelector: Selector? = nil, rightBtnTarget: Any? = nil, rightBtnThemeStyle: ThemeStyle = .primaryInteractive01, themeStyle: ThemeStyle) {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: SettingsTableHeader, _) in
            view.updateSize()
        }

        style = themeStyle

        titleLabel.style = .primaryText02
        titleLabel.themeOverride = themeOverride
        titleLabel.font = UIFont.font(ofSize: 13, weight: .regular, scalingWith: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.text = title.uppercased()

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let titleTrailing = titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        titleTrailing.priority = .defaultHigh
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.Values.tableSectionHeaderHeight),
            titleTrailing,
        ])

        if showLockedImage {
            let lockImage = UIImageView(image: UIImage(named: "settings_locked"))
            addSubview(lockImage)
            lockImage.contentMode = .scaleAspectFit
            lockImage.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                trailingAnchor.constraint(equalTo: lockImage.trailingAnchor, constant: 16),
                lockImage.heightAnchor.constraint(equalToConstant: 24),
                lockImage.widthAnchor.constraint(equalToConstant: 24),
                lockImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
            ])
            let tapGesture = UITapGestureRecognizer(target: lockedTarget, action: lockedSelector)
            addGestureRecognizer(tapGesture)
            self.lockImage = lockImage
        }

        if let rightBtnTitle, let rightBtnSelector, let rightBtnTarget {
            let rightBtn = ThemeableUIButton()
            rightBtn.setTitle(rightBtnTitle, for: .normal)
            rightBtn.titleLabel?.font = titleLabel.font
            rightBtn.titleLabel?.adjustsFontForContentSizeCategory = true
            rightBtn.translatesAutoresizingMaskIntoConstraints = false
            rightBtn.style = rightBtnThemeStyle
            rightBtn.addTarget(rightBtnTarget, action: rightBtnSelector, for: .touchUpInside)
            addSubview(rightBtn)
            NSLayoutConstraint.activate([
                rightBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                rightBtn.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 4),
                rightBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 0)
            ])
        }

        updateSize()
    }

    func addInfoButton(selector: Selector, target: Any, accessibilityLabel: String) {
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let infoButton = HitTargetButton(type: .system)
        infoButton.setImage(UIImage(named: "empty-playlist-info")?.withRenderingMode(.alwaysTemplate), for: .normal)
        infoButton.tintColor = AppTheme.colorForStyle(.primaryText02, themeOverride: themeOverride)
        infoButton.imageView?.contentMode = .scaleAspectFit
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.addTarget(target, action: selector, for: .touchUpInside)
        infoButton.accessibilityLabel = accessibilityLabel
        addSubview(infoButton)
        let iconSize: CGFloat = 18
        NSLayoutConstraint.activate([
            infoButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 6),
            infoButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: iconSize),
            infoButton.heightAnchor.constraint(equalToConstant: iconSize),
            trailingAnchor.constraint(greaterThanOrEqualTo: infoButton.trailingAnchor, constant: 16)
        ])
    }

    override func handleThemeDidChange() {
        if clearBackground {
            backgroundColor = .clear
        }
    }

    private func updateSize() {
        let iconMetric = UIFontMetrics(forTextStyle: .largeTitle)
        let iconSize = max(24, iconMetric.scaledValue(for: 24))
        lockImage?.updateSizeConstraints(to: iconSize)
    }
}
