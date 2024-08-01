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

    private lazy var doneButton: UIButton = createButton(
        title: L10n.done,
        action: #selector(done),
        titleColor: .label,
        highlightedTitleColor: .systemGray,
        contentInsets: .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    )

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

    override var intrinsicContentSize: CGSize {
        return .zero
    }

    init() {
        super.init(frame: .zero, inputViewStyle: .keyboard)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        overrideUserInterfaceStyle = .dark

        addSubview(mainStackView)
        mainStackView.addArrangedSubview(innerStackView)
        innerStackView.addArrangedSubview(doneButton)
        innerStackView.addArrangedSubview(textField)
        innerStackView.addArrangedSubview(upButton)
        innerStackView.addArrangedSubview(downButton)

        setupConstraints()
        configureHuggingAndCompressionPriorities()
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

    @objc func editingChanged() {
        delegate?.search(textField.text ?? "")
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
        textField.layer.cornerRadius = 8
        textField.backgroundColor = .systemGray3
        textField.rightLabel.text = "1/10"
        textField.rightLabel.textColor = .secondaryLabel
        textField.delegate = self
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.translatesAutoresizingMaskIntoConstraints = false
    }

    func createButton(title: String, action: Selector, titleColor: UIColor, highlightedTitleColor: UIColor, contentInsets: NSDirectionalEdgeInsets) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(highlightedTitleColor, for: .highlighted)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = contentInsets
        button.configuration = buttonConfig
        return button
    }

    func createSymbolButton(imageName: String, action: Selector, contentInsets: NSDirectionalEdgeInsets) -> UIButton {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: action, for: .touchUpInside)
        let config = UIImage.SymbolConfiguration(textStyle: .body)
        button.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
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
