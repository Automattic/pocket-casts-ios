import UIKit

class TranscriptSearchAcessoryView: UIInputView {
    let textView = UITextView()
    private var heightConstraint: NSLayoutConstraint!

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
        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .white
        textView.delegate = self

        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true

        heightConstraint = heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.isActive = true

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        textViewDidChange(textView)
    }
}

extension TranscriptSearchAcessoryView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = size.height + 16 // Add some padding
        if newHeight != heightConstraint.constant {
            heightConstraint.constant = newHeight
            layoutIfNeeded()
        }
    }
}
