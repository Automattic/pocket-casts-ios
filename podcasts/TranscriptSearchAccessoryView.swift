import UIKit

protocol TranscriptSearchAcessoryViewDelegate: AnyObject {
    // When "Done" is tapped on this view
    func doneTapped()

    // When "Search" is tapped on the keyboard
    func searchButtonTapped()
}

class TranscriptSearchAcessoryView: UIInputView {
    weak var delegate: TranscriptSearchAcessoryViewDelegate?

    lazy var textField: CustomTextField = {
        let textField = CustomTextField()
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.clearButtonMode = .whileEditing
        textField.layer.cornerRadius = 8
        textField.backgroundColor = .systemGray3

        textField.rightLabel.text = "1/10"
        textField.rightLabel.textColor = .secondaryLabel
        textField.delegate = self
        return textField
    }()

    private lazy var mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.addArrangedSubview(innerStackView)
        mainStackView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        mainStackView.isLayoutMarginsRelativeArrangement = true
        return mainStackView
    }()

    private lazy var innerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(done), for: .touchUpInside)
        button.setTitle(L10n.done, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.systemGray, for: .highlighted)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        button.configuration = buttonConfig
        return button
    }()

    private lazy var downButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(done), for: .touchUpInside)
        let config = UIImage.SymbolConfiguration(textStyle: .body)
        button.setImage(UIImage(systemName: "chevron.down", withConfiguration: config), for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.tintColor = .label

        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        button.configuration = buttonConfig
        return button
    }()

    private lazy var upButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(done), for: .touchUpInside)
        let config = UIImage.SymbolConfiguration(textStyle: .body)
        button.setImage(UIImage(systemName: "chevron.up", withConfiguration: config), for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.tintColor = .label

        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        button.configuration = buttonConfig
        return button
    }()

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

        textField.translatesAutoresizingMaskIntoConstraints = false

        // Set content hugging priority
        textField.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .horizontal)
        doneButton.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        upButton.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        downButton.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)

        // Set content compression resistance priority
        textField.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        doneButton.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        upButton.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        downButton.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)

        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true

        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func done() {
        textField.resignFirstResponder()
        delegate?.doneTapped()
    }
}

extension TranscriptSearchAcessoryView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.searchButtonTapped()
        return true
    }
}

class CustomTextField: UITextField {

    let rightLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabel()
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }

    private func setupLabel() {
        addSubview(rightLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let clearButtonWidth: CGFloat = clearButtonRect(forBounds: bounds).width
        let rightInset: CGFloat = isEditing && text?.isEmpty == false ? clearButtonWidth + 8 : 8
        rightLabel.sizeToFit()
        let labelWidth: CGFloat = rightLabel.frame.width

        let xPosition = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? rightInset : bounds.width - labelWidth - rightInset

        rightLabel.frame = CGRect(
            x: xPosition,
            y: (bounds.height - rightLabel.intrinsicContentSize.height) / 2,
            width: labelWidth,
            height: rightLabel.intrinsicContentSize.height
        )
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return adjustRect(forBounds: bounds)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return adjustRect(forBounds: bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return adjustRect(forBounds: bounds)
    }

    private func adjustRect(forBounds bounds: CGRect) -> CGRect {
        let labelWidth: CGFloat = rightLabel.frame.width
        let clearButtonWidth: CGFloat = clearButtonRect(forBounds: bounds).width
        let rightInset: CGFloat = isEditing && text?.isEmpty == false ? clearButtonWidth : 0
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            return bounds.inset(by: UIEdgeInsets(top: 0, left: labelWidth + rightInset + 16, bottom: 0, right: 8))
        } else {
            return bounds.inset(by: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: labelWidth + rightInset + 16))
        }
    }

    @objc private func editingChanged() {
        setNeedsLayout()
    }
}
