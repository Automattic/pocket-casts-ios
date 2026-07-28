import UIKit
import PocketCastsUtils

protocol TranscriptSearchAccessoryViewDelegate: AnyObject {
    // When "Done" is tapped on this view
    func doneTapped()

    // When "Search" is tapped on the keyboard
    func searchButtonTapped()

    // Text to search for
    func search(_ term: String)

    // Previous match requested
    func previousMatch()

    // Next match requested
    func nextMatch()
}

class TranscriptSearchAccessoryView: UIInputView {
    weak var delegate: TranscriptSearchAccessoryViewDelegate?

    var maxContentSizeCategory: UIContentSizeCategory = .extraExtraLarge

    lazy var textField: CustomTextField = {
        let textField = CustomTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        configureTextField(textField)
        return textField
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private lazy var innerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var doneButton: UIButton = {
        if #available(iOS 26.0, *) {
            return createDoneGlassButton()
        }
        return createButton(
            title: L10n.done,
            action: #selector(done),
            titleColor: .label,
            highlightedTitleColor: .systemGray,
            contentInsets: .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        )
    }()

    private lazy var downButton: UIButton = createSymbolButton(
        imageName: "chevron.down",
        action: #selector(nextMatch),
        contentInsets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)
    )

    private lazy var upButton: UIButton = createSymbolButton(
        imageName: "chevron.up",
        action: #selector(previousMatch),
        contentInsets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)
    )

    func enableUpDownButtons(_ enable: Bool) {
        upButton.isEnabled = enable
        downButton.isEnabled = enable
    }

    override var intrinsicContentSize: CGSize {
        return .zero
    }

    init(maxContentSizeCategory: UIContentSizeCategory = .extraExtraLarge) {
        self.maxContentSizeCategory = maxContentSizeCategory
        super.init(frame: .zero, inputViewStyle: .keyboard)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: TranscriptSearchAccessoryView, _) in
            view.updateSize()
        }

        overrideUserInterfaceStyle = .dark

        addSubview(mainStackView)
        mainStackView.addArrangedSubview(innerStackView)
        innerStackView.addArrangedSubview(doneButton)

        // On iOS 26 the keyboard input view is transparent, so we float the field
        // and the navigation buttons as Liquid Glass capsules over the keyboard.
        // Older versions keep the previous flat layout backed by the keyboard style.
        if #available(iOS 26.0, *) {
            innerStackView.spacing = 8
            // Fill so the field capsule matches the height of the chevron capsule.
            innerStackView.alignment = .fill
            mainStackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            mainStackView.isLayoutMarginsRelativeArrangement = true

            // Keep the Done checkmark circular by matching its width to its height.
            doneButton.widthAnchor.constraint(equalTo: doneButton.heightAnchor).isActive = true

            let fieldContainer = makeGlassContainer(wrapping: textField)
            fieldContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            fieldContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            innerStackView.addArrangedSubview(fieldContainer)

            let chevronStackView = UIStackView(arrangedSubviews: [upButton, downButton])
            chevronStackView.axis = .horizontal
            let chevronContainer = makeGlassContainer(wrapping: chevronStackView)
            chevronContainer.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            chevronContainer.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            innerStackView.addArrangedSubview(chevronContainer)
        } else {
            innerStackView.addArrangedSubview(textField)
            innerStackView.addArrangedSubview(upButton)
            innerStackView.addArrangedSubview(downButton)
        }

        setupConstraints()
        configureHuggingAndCompressionPriorities()
        updateSize()
    }

    @objc private func done() {
        textField.resignFirstResponder()
        delegate?.doneTapped()
    }

    @objc private func previousMatch() {
        delegate?.previousMatch()
    }

    @objc private func nextMatch() {
        delegate?.nextMatch()
    }

    @objc private func editingChanged() {
        delegate?.search(textField.text ?? "")
    }

    func updateLabel(_ text: String) {
        textField.rightLabel.text = text
        textField.rightLabel.sizeToFit()
    }

    func updateSize() {
        textField.font = UIFont.font(with: .body, maxSizeCategory: maxContentSizeCategory)
        textField.rightLabel.font = UIFont.font(with: .callout, maxSizeCategory: maxContentSizeCategory)
        doneButton.titleLabel?.font = UIFont.font(with: .callout, maxSizeCategory: maxContentSizeCategory)
        let config = UIImage.SymbolConfiguration(pointSize: UIFont.font(with: .callout, maxSizeCategory: maxContentSizeCategory).pointSize)
        upButton.setImage(UIImage(systemName: "chevron.up")?.withConfiguration(config), for: .normal)
        downButton.setImage(UIImage(systemName: "chevron.down")?.withConfiguration(config), for: .normal)
    }
}

extension TranscriptSearchAccessoryView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.searchButtonTapped()
        return true
    }
}

// MARK: - Configuration Helpers

private extension TranscriptSearchAccessoryView {
    func configureTextField(_ textField: CustomTextField) {
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.clearButtonMode = .whileEditing
        if #available(iOS 26.0, *) {
            // The surrounding glass capsule provides the background and shape.
            textField.backgroundColor = .clear
        } else {
            textField.layer.cornerRadius = 8
            textField.backgroundColor = .systemGray3
        }
        textField.rightLabel.textColor = .secondaryLabel
        textField.delegate = self
        textField.font = UIFont.font(with: .body, maxSizeCategory: maxContentSizeCategory)
        textField.adjustsFontForContentSizeCategory = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.rightLabel.font = UIFont.font(with: .callout, maxSizeCategory: maxContentSizeCategory)
        textField.rightLabel.adjustsFontForContentSizeCategory = false
    }

    @available(iOS 26.0, *)
    func createDoneGlassButton() -> UIButton {
        var config = UIButton.Configuration.prominentGlass()
        config.image = UIImage(systemName: "checkmark")
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.accessibilityLabel = L10n.done
        button.addTarget(self, action: #selector(done), for: .touchUpInside)
        return button
    }

    @available(iOS 26.0, *)
    func makeGlassContainer(wrapping content: UIView) -> UIVisualEffectView {
        let effect = UIGlassEffect()
        effect.isInteractive = true
        let container = UIVisualEffectView(effect: effect)
        container.cornerConfiguration = .capsule()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.contentView.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor),
            content.topAnchor.constraint(equalTo: container.contentView.topAnchor),
            content.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor)
        ])
        return container
    }

    func createButton(title: String, action: Selector, titleColor: UIColor, highlightedTitleColor: UIColor, contentInsets: NSDirectionalEdgeInsets) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(self, action: action, for: .touchUpInside)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: titleColor,
            .font: UIFont.font(with: .callout, maxSizeCategory: maxContentSizeCategory)
        ]
        button.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(highlightedTitleColor, for: .highlighted)

        button.titleLabel?.adjustsFontForContentSizeCategory = false

        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = contentInsets
        button.configuration = buttonConfig
        return button
    }

    func createSymbolButton(imageName: String, action: Selector, contentInsets: NSDirectionalEdgeInsets) -> UIButton {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: action, for: .touchUpInside)
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: imageName)?.withConfiguration(config), for: .normal)
        button.titleLabel?.font = UIFont.font(with: .callout, maxSizeCategory: maxContentSizeCategory)
        button.titleLabel?.adjustsFontForContentSizeCategory = false
        button.tintColor = .label

        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = contentInsets
        button.configuration = buttonConfig
        return button
    }

    func setupConstraints() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configureHuggingAndCompressionPriorities() {
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        doneButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        upButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        downButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        doneButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        upButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        downButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
}
