import UIKit

class SimpleActionView: UIView {
    private let action: OptionAction
    private let themeOverride: Theme.ThemeType?
    private let iconTintStyle: ThemeStyle

    private weak var delegate: OptionsPickerRootController?
    private var onOffSwitch: UISwitch?
    private var imageView: UIImageView?
    private var selectedView: UIImageView?

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
        label.font = UIFont.font(ofSize: 18, weight: .semibold, scalingWith: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = action.label
        label.textColor = action.destructive ? AppTheme.destructiveTextColor(for: themeOverride) : AppTheme.mainTextColor(for: themeOverride)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
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
            ])
            self.imageView = imageView
        } else {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            ])
        }
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        var previousView: UIView = label

        if let secondaryText = action.secondaryLabel {
            let secondaryLabel = UILabel()
            secondaryLabel.font = UIFont.font(ofSize: 16, weight: .semibold, scalingWith: .callout)
            secondaryLabel.adjustsFontForContentSizeCategory = true
            secondaryLabel.numberOfLines = 0
            secondaryLabel.text = secondaryText            
            secondaryLabel.contentMode = .right
            secondaryLabel.textColor = ThemeColor.primaryText02(for: themeOverride)
            secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(secondaryLabel)

            NSLayoutConstraint.activate([
                secondaryLabel.topAnchor.constraint(equalTo: topAnchor),
                secondaryLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            previousView = secondaryLabel
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
            previousView = onOffSwitch
        } else if action.selected {
            let image = UIImage(named: "small-tick")?.tintedImage(ThemeColor.primaryIcon01(for: themeOverride))
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            selectedView = imageView
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24)
            ])
            previousView = imageView
        }
        if previousView != label {
            label.trailingAnchor.constraint(equalTo: previousView.leadingAnchor, constant: -10).isActive = true
        }
        trailingAnchor.constraint(equalTo: previousView.trailingAnchor, constant: 20).isActive = true


        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(actionTapped))
        addGestureRecognizer(tapGesture)

        isAccessibilityElement = true
        accessibilityLabel = action.label
        isUserInteractionEnabled = true
        accessibilityTraits = [.button]

        updateSize()
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

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let imageSize = max(24, metric.scaledValue(for: 24))

        if let imageView {
            imageView.updateSizeConstraints(to: imageSize)
        }

        if let selectedView {
            selectedView.updateSizeConstraints(to: imageSize)
        }
    }


    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory else { return }
        updateSize()
    }
}
