import SwiftUI
@preconcurrency import WebKit

struct PodcastHeaderDescriptionView: UIViewRepresentable {
    let htmlDescription: String
    weak var delegate: ExpandableLabelDelegate?
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self, delegate: delegate)
    }

    func makeUIView(context: Context) -> WKWebView {
        let wkwebView = WKWebView(frame: .zero)
        context.coordinator.webView = wkwebView
        return wkwebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.webView = uiView
        context.coordinator.updateStyle()
        context.coordinator.setRichText(html: htmlDescription)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PodcastHeaderDescriptionView
        var webView: WKWebView
        var collapsed = false
        var htmlReady: Bool = false
        var isFirstTime: Bool = true
        var contentHeight: CGFloat = 0 {
            didSet {
                parent.contentHeight = contentHeight
            }
        }
        var maxLines = 3
        private var previousHTML: String = ""

        weak var delegate: ExpandableLabelDelegate?

        init(_ parent: PodcastHeaderDescriptionView, delegate: ExpandableLabelDelegate?) {
            self.parent = parent
            self.webView = WKWebView()
            self.delegate = delegate
            webView.isOpaque = false
            webView.scrollView.backgroundColor = .clear
            webView.backgroundColor = .clear
        }

        func setRichText(html: String) {
            webView.navigationDelegate = self
            let styledHTML = style(html: html)
            guard previousHTML != styledHTML else {
                return
            }
            htmlReady = false
            previousHTML = styledHTML
            webView.loadHTMLString(styledHTML, baseURL: nil)
        }

        private func style(html: String) -> String {
            let backgroundColor: UIColor = ThemeColor.primaryUi02()
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
                line-height: \(1.3);
                background-color: \(backgroundColor.hexString());
                color: \(textColor.hexString());
                margin: 0;
                padding: 0;
            }
            .clipping {
              display: -webkit-box;
              -webkit-line-clamp: \(3);
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

        private func update() {
//            if collapsed {
//                addGestureRecognizer(linkTapGesture)
//                let font = UIFont.preferredFont(forTextStyle: .body)
//                heightConstraint.constant = font.lineHeight * desiredLinedHeightMultiple * CGFloat(maxLines)
//            } else {
//                removeGestureRecognizer(linkTapGesture)
//                heightConstraint.constant = contentHeight
//            }
            if htmlReady {
                toggleColapseHTMLContent(on: collapsed)
            }
            //webView.setNeedsLayout()
            //webView.sizeToFit()
        }

        private func updateScrollSize() {
            webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] height, _ in
                guard let self = self, let cgHeight = height as? CGFloat else { return }

                contentHeight = CGFloat(cgHeight)
                htmlReady = true
                update()
                if isFirstTime {
                    isFirstTime = false
                    updateLinesRequired()
                }
            })
        }

        private func updateLinesRequired() {
            webView.evaluateJavaScript("countLines()", completionHandler: { [weak self] lines, error in
                guard let self = self, let linesRequired = lines as? Int else { return }
                collapsed = linesRequired > self.maxLines
            })
        }

        private func toggleColapseHTMLContent(on: Bool) {
            webView.evaluateJavaScript(on ? "toggleClipping(true)" : "toggleClipping(false)", completionHandler: nil)
        }

        func updateStyle() {
            webView.isOpaque = false
            webView.scrollView.backgroundColor = .clear
            webView.backgroundColor = .clear
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.readyState", completionHandler: { [weak self] complete, _ in
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

}
