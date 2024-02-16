import UIKit

class SimpleActionView: UIView {
    private let action: OptionAction
    private let themeOverride: Theme.ThemeType?
    private let iconTintStyle: ThemeStyle

    private weak var delegate: OptionsPickerRootController?
    private var onOffSwitch: UISwitch?

    init(frame: CGRect, action: OptionAction, delegate: OptionsPickerRootController, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle = .primaryIcon01) {
        self.action = action
        self.delegate = delegate
        self.themeOverride = themeOverride
        self.iconTintStyle = iconTintStyle
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func actionWasAdded() {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 2
        label.text = action.label
        label.textColor = action.destructive ? AppTheme.destructiveTextColor(for: themeOverride) : AppTheme.mainTextColor(for: themeOverride)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        let iconTintColor = action.destructive ? AppTheme.destructiveTextColor(for: themeOverride) : AppTheme.colorForStyle(iconTintStyle, themeOverride: themeOverride)

        var image = action.icon.flatMap { UIImage(named: $0) }

        if action.tintIcon {
            image = image?.tintedImage(iconTintColor)
        }

        if let image {
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
                label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }

        if let secondaryText = action.secondaryLabel {
            let secondaryLabel = UILabel()
            secondaryLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            secondaryLabel.numberOfLines = 2
            secondaryLabel.text = secondaryText
            // swiftlint:disable:next inverse_text_alignment
            secondaryLabel.textAlignment = .right
            secondaryLabel.textColor = ThemeColor.primaryText02(for: themeOverride)
            secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
            secondaryLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            addSubview(secondaryLabel)

            NSLayoutConstraint.activate([
                secondaryLabel.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10),
                trailingAnchor.constraint(equalTo: secondaryLabel.trailingAnchor, constant: 20),
                secondaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        } else {
            trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 20).isActive = true
        }

        if action.onOffAction {
            let onOffSwitch = ThemeableSwitch()
            onOffSwitch.isOn = action.selected
            onOffSwitch.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            onOffSwitch.translatesAutoresizingMaskIntoConstraints = false
            addSubview(onOffSwitch)

            NSLayoutConstraint.activate([
                trailingAnchor.constraint(equalTo: onOffSwitch.trailingAnchor, constant: 20),
                onOffSwitch.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])

            self.onOffSwitch = onOffSwitch
        } else if action.selected {
            let image = UIImage(named: "small-tick")?.tintedImage(ThemeColor.primaryIcon01(for: themeOverride))
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)

            NSLayoutConstraint.activate([
                trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24)
            ])
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(actionTapped))
        addGestureRecognizer(tapGesture)

        isAccessibilityElement = true
        accessibilityLabel = action.label
        isUserInteractionEnabled = true
        accessibilityTraits = [.button]
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }

            self.backgroundColor = ThemeColor.primaryUi01Active(for: self.themeOverride)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.backgroundColor = UIColor.clear
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.backgroundColor = UIColor.clear
        }
    }

    @objc private func switchToggled(_ sender: UISwitch) {
        action.action()
    }

    @objc private func actionTapped() {
        action.action()

        if action.onOffAction {
            guard let onOffSwitch = onOffSwitch else { return }

            onOffSwitch.isOn = !onOffSwitch.isOn
        } else {
            delegate?.animateOut(optionChosen: true)
        }
    }
}
