import UIKit
import PocketCastsUtils

class DescriptiveActionView: UIView {
    private let title: String
    private let message: String?
    private let icon: String
    private let actions: [OptionAction]
    private let themeOverride: Theme.ThemeType?
    private let iconTintStyle: ThemeStyle
    private let onLinkTap: (() -> Void)?

    private weak var iconView: UIImageView?

    private weak var delegate: OptionsPickerRootController?

    init(frame: CGRect, title: String, message: String?, icon: String, actions: [OptionAction], delegate: OptionsPickerRootController, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle = .primaryIcon01, onLinkTap: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actions = actions
        self.delegate = delegate
        self.themeOverride = themeOverride
        self.iconTintStyle = iconTintStyle
        self.onLinkTap = onLinkTap
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func actionWasAdded() {
        // add icon
        let image = UIImage(named: icon)?.tintedImage(AppTheme.colorForStyle(iconTintStyle, themeOverride: themeOverride))
        let iconView = UIImageView(image: image)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 39),
            iconView.widthAnchor.constraint(equalToConstant: 39)
        ])
        self.iconView = iconView

        // add title
        let titleLabel = UILabel()
        titleLabel.font = UIFont.font(ofSize: 20, weight: .bold, scalingWith: .title3)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        titleLabel.textColor = AppTheme.mainTextColor(for: themeOverride)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 20)
        ])

        // add message
        let messageBottomAnchor: NSLayoutYAxisAnchor
        if FeatureFlag.useDescriptiveActionAttributedTextView.enabled, let message {
            let messageView = DescriptiveActionAttributedTextView(
                text: message,
                onLinkTap: onLinkTap
            ).themedUIView
            messageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(messageView)            
            NSLayoutConstraint.activate([
                messageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                messageView.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
                messageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: 20)
            ])
            messageBottomAnchor = messageView.bottomAnchor
            messageView.setContentHuggingPriority(.defaultLow, for: .vertical)
            messageView.setContentCompressionResistancePriority(.required, for: .vertical)
        } else {
            let messageLabel = UILabel()
            messageLabel.font = UIFont.font(ofSize: 15, weight: .regular, scalingWith: .subheadline)
            messageLabel.adjustsFontForContentSizeCategory = true
            messageLabel.text = message
            messageLabel.textColor = AppTheme.mainTextColor(for: themeOverride)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            addSubview(messageLabel)

            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 20)
            ])
            messageBottomAnchor = messageLabel.bottomAnchor
            messageLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
            messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        }
        var previousBottomAnchor = messageBottomAnchor

        for (index, action) in actions.enumerated() {
            let actionButton = ShiftyRoundButton()
            actionButton.fontSize = 18
            actionButton.buttonTitle = action.label
            actionButton.isAccessibilityElement = true
            actionButton.accessibilityLabel = action.label
            actionButton.accessibilityIdentifier = "action_\(index)"
            actionButton.accessibilityTraits = [.button]
            let actionColor = action.destructive ? AppTheme.destructiveTextColor() : ThemeColor.primaryIcon01(for: themeOverride)
            actionButton.textColor = action.outline ? actionColor : ThemeColor.primaryInteractive02(for: themeOverride)
            actionButton.fillColor = actionColor
            actionButton.strokeColor = actionColor
            actionButton.isOn = !action.outline
            actionButton.setup()
            actionButton.buttonTapped = { [weak self] in
                action.action()
                self?.delegate?.animateOut(optionChosen: true)
            }
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(actionButton)

            NSLayoutConstraint.activate([
                actionButton.topAnchor.constraint(equalTo: previousBottomAnchor, constant: 20),
                actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                actionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 20),
                actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
            ])
            previousBottomAnchor = actionButton.bottomAnchor
        }

        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: previousBottomAnchor, constant: 20)
        ])

        updateSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }

    private func updateSize() {
        let iconMetric = UIFontMetrics(forTextStyle: .largeTitle)
        let iconSize = max(39, iconMetric.scaledValue(for: 39))
        iconView?.updateSizeConstraints(to: iconSize)
    }
}
