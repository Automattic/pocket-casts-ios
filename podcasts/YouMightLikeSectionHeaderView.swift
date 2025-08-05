import UIKit

class YouMightLikeSectionHeaderView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = ThemeColor.primaryText02()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = ThemeColor.primaryText02()
        return label
    }()

    var onTapped: (() -> Void)?

    init(image: UIImage?, title: String) {
        super.init(frame: .zero)
        icon.image = image
        label.text = title
        setup()
        addTapGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        addTapGesture()
    }

    private func setup() {
        backgroundColor = .clear

        addSubview(stackView)
        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
    }

    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }

    @objc private func headerTapped() {
        onTapped?()
    }
}
