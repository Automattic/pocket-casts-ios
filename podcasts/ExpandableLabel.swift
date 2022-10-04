import UIKit

protocol ExpandableLabelDelegate: NSObjectProtocol {
    func willExpandLabel(_ label: ExpandableLabel)
    func didExpandLabel(_ label: ExpandableLabel)
}

class ExpandableLabel: ThemeableLabel {
    weak var delegate: ExpandableLabelDelegate?
    var desiredLinedHeightMultiple: CGFloat = 1
    var maxLines = 3

    var collapsed = false {
        didSet {
            update()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        addGestureRecognizer(tapGesture)
    }

    func setTextKeepingExistingAttributes(text: String?) {
        setTextKeepingAttributes(string: text ?? "")

        collapsed = linesRequired() > maxLines
    }

    @objc private func labelTapped() {
        if collapsed {
            delegate?.willExpandLabel(self)

            collapsed = false

            delegate?.didExpandLabel(self)
        }
    }

    private func update() {
        if collapsed {
            numberOfLines = maxLines
            lineBreakMode = .byTruncatingTail

            sizeToFit()
        } else {
            lineBreakMode = .byWordWrapping
            numberOfLines = 0
            sizeToFit()
        }
    }

    private func linesRequired() -> Int {
        guard let text = text else { return 1 }

        layoutIfNeeded()

        let alteredText = "\(text)..."
        let attributes = [NSAttributedString.Key.font: font as UIFont]
        let labelSize = alteredText.boundingRect(with: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil)

        return Int(ceil(CGFloat(labelSize.height) / (font.lineHeight * desiredLinedHeightMultiple)))
    }
}
