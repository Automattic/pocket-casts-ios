import SwiftUI
import WebKit

struct StoriesWebView: UIViewRepresentable {
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: StoriesWebView

        init(parent: StoriesWebView) {
            self.parent = parent
        }

        // This receives messages from the web content
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "closeStories" {
                NavigationManager.sharedManager.dismissPresentedViewController()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "closeStories") // Add JS -> iOS handler
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)

        webView.isOpaque = false
            webView.backgroundColor = .white
            webView.scrollView.backgroundColor = .white
            webView.scrollView.contentInsetAdjustmentBehavior = .never

        if let url = URL(string: "http://localhost:3000/eoy/") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
