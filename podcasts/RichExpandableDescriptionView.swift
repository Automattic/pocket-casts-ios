import UIKit
@preconcurrency import WebKit

class RichExpandableLabel: WKWebView {

    weak var delegate: ExpandableLabelDelegate?
    var desiredLinedHeightMultiple: CGFloat = 1.4
    var maxLines = 3
    private var heightConstraint: NSLayoutConstraint!
    private var contentHeight: CGFloat = 0
    private var htmlReady: Bool = false
    private(set) var previousHTML: String = ""
    private var isFirstTime = true

    private lazy var linkTapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.delegate = self
        return tapGesture
    }()

    var collapsed = false {
        didSet {
            update()
        }
    }

    init() {
        super.init(frame: .zero, configuration: WKWebViewConfiguration())
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        self.heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            heightConstraint
        ])
        isUserInteractionEnabled = true
        scrollView.isScrollEnabled = false
        navigationDelegate = self
        updateStyle()
    }

    func reset() {
        htmlReady = false
        previousHTML = ""
        frame = .zero
        heightConstraint.constant = 0
    }

    private func updateStyle() {
        isOpaque = false
        scrollView.backgroundColor = .clear
        backgroundColor = .clear
    }

    func setRichText(html: String) {
        let styledHTML = style(html: html)
        guard previousHTML != styledHTML else {
            if htmlReady {
                delegate?.heightChanged(newHeight: heightConstraint.constant.rounded(.up))
            }
            return
        }
        htmlReady = false
        previousHTML = styledHTML
        self.loadHTMLString(styledHTML, baseURL: nil)
    }

    private func style(html: String) -> String {
        let  backgroundColor: UIColor = ThemeColor.primaryUi02()
        let textColor: UIColor = ThemeColor.primaryText01()
        let linkColor: UIColor = ThemeColor.primaryIcon01()
        let font = UIFont.preferredFont(forTextStyle: .body)
        let styledHTML: String = """
        <html>
        <head>
        <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
        <script>
        function countLines() {
           var el = document.body;
           var divHeight = el.scrollHeight;
           var lineHeight = parseInt(window.getComputedStyle(el).lineHeight);
           return divHeight / lineHeight;
        };
        function toggleClipping(on) {
            var container = document.getElementById("container");
            if (on) {
                container.classList.add("clipping");
            } else {
                container.classList.remove("clipping");
            }
        };
        </script>
        <style>
        body {
            font-family: -apple-system;
            font-size: \(font.pointSize)px;
            line-height: \(desiredLinedHeightMultiple);
            background-color: \(backgroundColor.hexString());
            color: \(textColor.hexString());
            margin: 0;
            padding: 0;
        }
        .clipping {
          display: -webkit-box;
          -webkit-line-clamp: \(maxLines);
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
        a {
            color:\(linkColor.hexString());
        }
        </style>
        </head>
        <body>
        <div id="container">
        \(html)
        </div>
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
            addGestureRecognizer(linkTapGesture)
            let font = UIFont.preferredFont(forTextStyle: .body)
            let newHeight = font.lineHeight * desiredLinedHeightMultiple * CGFloat(maxLines)
            heightConstraint.constant = newHeight
            delegate?.heightChanged(newHeight: newHeight.rounded(.up))
        } else {
            removeGestureRecognizer(linkTapGesture)
            heightConstraint.constant = contentHeight
            delegate?.heightChanged(newHeight: contentHeight.rounded(.up))
        }
        if htmlReady {
            toggleColapseHTMLContent(on: collapsed)
        }
        setNeedsLayout()
        sizeToFit()
    }

    private func updateScrollSize() {
        evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] height, _ in
            guard let self = self, let cgHeight = height as? CGFloat else { return }

            contentHeight = CGFloat(cgHeight)
            htmlReady = true
            if isFirstTime {
                isFirstTime = false
                updateLinesRequired()
            } else {
                update()
            }
        })
    }

    private func updateLinesRequired() {
        evaluateJavaScript("countLines()", completionHandler: { [weak self] lines, error in
            guard let self = self, let linesRequired = lines as? Double else { return }
            collapsed = Int(linesRequired.rounded(.up)) > self.maxLines
        })
    }

    private func toggleColapseHTMLContent(on: Bool) {
        evaluateJavaScript(on ? "toggleClipping(true)" : "toggleClipping(false)", completionHandler: nil)
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
            updateStyle()
            updateScrollSize()
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
