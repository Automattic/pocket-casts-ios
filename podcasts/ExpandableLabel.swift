import UIKit

protocol ExpandableLabelDelegate: NSObjectProtocol {
    func willExpandLabel(_ label: UIView)
    func didExpandLabel(_ label: UIView)

    func willCollapseLabel(_ label: UIView)
    func didCollapseLabel(_ label: UIView)

    func linkTapped(url: URL)
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

    func setRichText(html: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setRichText(html: html)
            }
            return
        }
        // We detected that some scenarios when this code is run when the app is backgrounded, it crashes even on the main thread.
        if UIApplication.shared.applicationState == .background {
            return
        }
        let styledHTML: String = """
        <html>
        <head>
        <style>
        body {
            font-family: -apple-system;
            font-size: 1.34em;
            line-height: 1.3;
        }
        </style>
        </head>
        <body>
        \(html)
        </body>
        </html>
        """
        guard let data = styledHTML.data(using: .utf8) else {
            return
        }
        let result = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSUTF8StringEncoding], documentAttributes: nil)
        attributedText = result
        textColor = AppTheme.colorForStyle(style)
        collapsed = linesRequired() > maxLines
    }

    @objc private func labelTapped(gesture: UITapGestureRecognizer) {
        if let url = gesture.didTapLinkInLabel(label: self) {
            delegate?.linkTapped(url: url)
            return
        }
        if collapsed {
            delegate?.willExpandLabel(self)
            collapsed = false
            delegate?.didExpandLabel(self)
        } else {
            delegate?.willCollapseLabel(self)
            collapsed = true
            delegate?.didCollapseLabel(self)
        }
        update()
    }

    private func update() {
        if collapsed {
            numberOfLines = maxLines
            lineBreakMode = .byTruncatingTail
            setNeedsLayout()
            sizeToFit()
        } else {
            lineBreakMode = .byWordWrapping
            numberOfLines = 0
            setNeedsLayout()
            sizeToFit()
        }
    }

    private func linesRequired() -> Int {
        if let attributedText {
            layoutIfNeeded()
            let labelSize = attributedText.boundingRect(with: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude), context: nil)

            return Int(ceil(CGFloat(labelSize.height) / (font.lineHeight * desiredLinedHeightMultiple)))
        } else {
            guard let text = text else { return 1 }

            layoutIfNeeded()

            let alteredText = "\(text)..."
            let attributes = [NSAttributedString.Key.font: font as UIFont]
            let labelSize = alteredText.boundingRect(with: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil)

            return Int(ceil(CGFloat(labelSize.height) / (font.lineHeight * desiredLinedHeightMultiple)))
        }
    }
}

extension UITapGestureRecognizer {
    func didTapLinkInLabel(label: UILabel) -> URL? {
            guard let attributedText = label.attributedText else {
                return nil
            }
            // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(size: CGSize.zero)
            let textStorage = NSTextStorage(attributedString: attributedText)

            // Configure layoutManager and textStorage
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)

            // Configure textContainer
            textContainer.lineFragmentPadding = 0.0
            textContainer.lineBreakMode = label.lineBreakMode
            textContainer.maximumNumberOfLines = label.numberOfLines
            let labelSize = label.bounds.size
            textContainer.size = labelSize

            // Find the tapped character location and compare it to the specified range
            let locationOfTouchInLabel = self.location(in: label)
            let textBoundingBox = layoutManager.usedRect(for: textContainer)
            let textContainerOffset = CGPoint(
                x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
            )
            let locationOfTouchInTextContainer = CGPoint(
                x: locationOfTouchInLabel.x - textContainerOffset.x,
                y: locationOfTouchInLabel.y - textContainerOffset.y
            )
            let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

            let attributes = attributedText.attributes(at: indexOfCharacter, effectiveRange: nil)
            let link = attributes[NSAttributedString.Key.link] as? URL
            return link
        }
}
