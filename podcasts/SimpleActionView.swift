import UIKit

class SimpleActionView: UIView {
    private let action: OptionAction
    private let themeOverride: Theme.ThemeType?
    private let iconTintStyle: ThemeStyle

    private weak var delegate: OptionsPickerRootController?
    private var onOffSwitch: UISwitch?
    private var imageView: UIImageView?
    private var selectedView: UIImageView?

    private var label: UILabel!
    private var secondaryLabel: UILabel?
    private var textStack: UIStackView?
    private var textView: UIView!
    private var labelVerticalConstraints: [NSLayoutConstraint] = []

    init(frame: CGRect, action: OptionAction, delegate: OptionsPickerRootController, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle = .primaryIcon01) {
        self.action = action
        self.delegate = delegate
        self.themeOverride = themeOverride
        self.iconTintStyle = iconTintStyle
        super.init(frame: frame)

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: SimpleActionView, _) in
            view.updateSize()
        }
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
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.init(rawValue: 751), for: .horizontal)
        var textView: UIView = label
        if let secondaryText = action.secondaryLabel {
            let secondaryLabel = UILabel()
            secondaryLabel.font = UIFont.font(ofSize: 16, weight: .semibold, scalingWith: .callout)
            secondaryLabel.adjustsFontForContentSizeCategory = true
            secondaryLabel.numberOfLines = 0
            secondaryLabel.text = secondaryText
            // swiftlint:disable:next inverse_text_alignment
            secondaryLabel.textAlignment = .right
            secondaryLabel.textColor = ThemeColor.primaryText02(for: themeOverride)
            secondaryLabel.setContentCompressionResistancePriority(.init(rawValue: 749), for: .horizontal)

            let textStack = UIStackView(arrangedSubviews: [label, secondaryLabel])
            textStack.spacing = 24
            self.textStack = textStack
            self.secondaryLabel = secondaryLabel
            textView = textStack
        }
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)
        self.textView = textView
        let iconTintColor = action.destructive ? AppTheme.destructiveTextColor(for: themeOverride) : AppTheme.colorForStyle(iconTintStyle, themeOverride: themeOverride)

        var image = action.icon.flatMap { UIImage(named: $0) }

        if action.tintIcon {
            image = image?.tintedImage(iconTintColor)
        }

        if let image {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                textView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
            ])
            self.imageView = imageView
        } else {
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            ])
        }
        labelVerticalConstraints = [
            textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(labelVerticalConstraints)
        self.label = label
        var previousView: UIView = textView

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
        if previousView != textView {
            textView.trailingAnchor.constraint(equalTo: previousView.leadingAnchor, constant: -24).isActive = true
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

    /// In sheet presentation the action view can sit at the bottom safe area,
    /// which inflates `layoutMarginsGuide.bottomAnchor` and leaves the label
    /// stuck to the top while the icon centers — visibly misaligned. Anchor
    /// the labels to the view's centerY (matching the icon) and keep the
    /// 8pt padding manually so safe area can't leak in.
    func configureForSheetPresentation() {
        NSLayoutConstraint.deactivate(labelVerticalConstraints)
        labelVerticalConstraints = [
            textView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
            textView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            textView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        NSLayoutConstraint.activate(labelVerticalConstraints)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self else { return }

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
        if action.onOffAction {
            action.action()
            guard let onOffSwitch else { return }

            onOffSwitch.isOn = !onOffSwitch.isOn
        } else if let submenu = action.submenu?(), let delegate {
            action.action()
            submenu.present(from: delegate)
        } else {
            // The sheet is a real presented view controller. Start its
            // dismissal *before* running the action so that an action which
            // presents another screen doesn't hit "already presenting" — this
            // lets UIKit serialize the dismiss and the new presentation.
            delegate?.animateOut(optionChosen: true)
            action.action()
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

        if let textStack, let secondaryLabel {
            let isStacked = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
            textStack.axis = isStacked ? .vertical : .horizontal
            textStack.spacing = isStacked ? 4 : 24
            // swiftlint:disable:next inverse_text_alignment
            secondaryLabel.textAlignment = isStacked ? .natural : .right
        }
    }
}
