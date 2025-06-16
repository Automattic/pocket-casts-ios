import SwiftUI
import PocketCastsServer
import WebKit

struct StoriesWebView: UIViewRepresentable {
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: StoriesWebView
        var webView: WKWebView?

        init(parent: StoriesWebView) {
            self.parent = parent
        }

        // This receives messages from the web content
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "closeStories" {
                NavigationManager.sharedManager.dismissPresentedViewController()
            }

            if message.name == "shareStory" {
                shareWebViewScreenshot(webView: webView!)
            }

            if message.name == "loaded" {
                informUserInfo()
            }
        }

        func shareWebViewScreenshot(webView: WKWebView) {
                let config = WKSnapshotConfiguration()
                config.rect = webView.bounds

                webView.takeSnapshot(with: config) { image, error in
                    guard let image = image, error == nil else {
                        print("Snapshot failed: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }

                    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                    SceneHelper.rootViewController()?.present(activityVC, animated: true)
                }
            }

        func informUserInfo() {
            webView?.evaluateJavaScript("window.setUserData({subscriber: \(SubscriptionHelper.hasActiveSubscription() ? "true" : "false")});") { result, error in
                if let error = error {
                    print("JavaScript error: \(error)")
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "loaded")
        contentController.add(context.coordinator, name: "closeStories")
        contentController.add(context.coordinator, name: "shareStory")
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
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
