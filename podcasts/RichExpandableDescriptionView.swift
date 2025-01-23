import UIKit
@preconcurrency import WebKit

class RichExpandableLabel: WKWebView {

    weak var delegate: ExpandableLabelDelegate?
    var desiredLinedHeightMultiple: CGFloat = 1.4
    var maxLines = 3
    private var heightConstraint: NSLayoutConstraint!
    private var contentHeight: CGFloat = 0

    var collapsed = false {
        didSet {
            update()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        translatesAutoresizingMaskIntoConstraints = false
        self.heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            heightConstraint
        ])
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.delegate = self
        scrollView.addGestureRecognizer(tapGesture)
        scrollView.isScrollEnabled = false
        scrollView.backgroundColor = .clear
        backgroundColor = .clear
        self.navigationDelegate = self
    }

    func setRichText(html: String) {
        let styledHTML = style(html: html)
        self.loadHTMLString(styledHTML, baseURL: nil)
        collapsed = linesRequired() > maxLines
    }

    private func style(html: String) -> String {
        let  backgroundColor: UIColor = ThemeColor.primaryUi02()
        let textColor: UIColor = ThemeColor.primaryText01()
        let linkColor: UIColor = ThemeColor.primaryIcon01()
        let styledHTML: String = """
        <html>
        <head>
        <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
        <style>
        body {
            font-family: -apple-system;
            font-size: 1.34em;
            line-height: \(desiredLinedHeightMultiple);
            background-color: \(backgroundColor.hexString());
            color: \(textColor.hexString());
            margin: 0;
            padding: 0;
        }
        a { 
            color:\(linkColor.hexString());
        }
        </style>
        </head>
        <body>
        \(html)
        </body>
        </html>
        """
        return styledHTML
    }

    @objc private func labelTapped(gesture: UITapGestureRecognizer) {
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
            let font = UIFont.preferredFont(forTextStyle: .body)
            heightConstraint.constant = font.lineHeight * desiredLinedHeightMultiple * CGFloat(maxLines)
        } else {
            heightConstraint.constant = contentHeight
        }
        setNeedsLayout()
        sizeToFit()
    }

    private func linesRequired() -> Int {
//        if let attributedText {
//            layoutIfNeeded()
//            let labelSize = attributedText.boundingRect(with: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude), context: nil)
//
//            return Int(ceil(CGFloat(labelSize.height) / (font.lineHeight * desiredLinedHeightMultiple)))
//        } else {
//            guard let text = text else { return 1 }
//
//            layoutIfNeeded()
//
//            let alteredText = "\(text)..."
//            let attributes = [NSAttributedString.Key.font: font as UIFont]
//            let labelSize = alteredText.boundingRect(with: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil)
//
//            return Int(ceil(CGFloat(labelSize.height) / (font.lineHeight * desiredLinedHeightMultiple)))
//        }
        return 1
    }
}

extension RichExpandableLabel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        evaluateJavaScript("document.readyState", completionHandler: { [weak self] complete, _ in
            guard let self = self,
                  let result = complete as? String,
                  result == "complete" // ensure that the load of HTML is complete and not in another loading state
            else {
                return
            }
            updateScrollSize()
        })
    }

    func updateScrollSize() {
        evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] height, _ in
            guard let self = self, let cgHeight = height as? CGFloat else { return }

            contentHeight = CGFloat(cgHeight)
            update()
        })
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated else {
            decisionHandler(.allow)
            return
        }

        delegate?.linkTapped(url: url)

        decisionHandler(.cancel)
    }
}

extension RichExpandableLabel: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
