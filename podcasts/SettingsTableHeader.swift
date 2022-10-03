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

    private func setupView(title: String, showLockedImage: Bool = false, lockedSelector: Selector? = nil, lockedTarget: Any? = nil, rightBtnTitle: String? = nil, rightBtnSelector: Selector? = nil, rightBtnTarget: Any? = nil, rightBtnThemeStyle: ThemeStyle = .primaryInteractive01, themeStyle: ThemeStyle) {
        style = themeStyle

        titleLabel.style = .primaryText02
        titleLabel.themeOverride = themeOverride
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        titleLabel.text = title.uppercased()

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
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
        }

        if let rightBtnTitle = rightBtnTitle, let rightBtnSelector = rightBtnSelector, let rightBtnTarget = rightBtnTarget {
            let rightBtn = ThemeableUIButton()
            rightBtn.setTitle(rightBtnTitle, for: .normal)
            rightBtn.titleLabel?.font = titleLabel.font
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
    }

    override func handleThemeDidChange() {
        if clearBackground {
            backgroundColor = .clear
        }
    }
}
