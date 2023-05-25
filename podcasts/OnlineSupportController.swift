import MessageUI
import SwiftUI
import PocketCastsServer
import UIKit
import WebKit

class OnlineSupportController: PCViewController, WKNavigationDelegate {
    @IBOutlet var loadingIndicator: AngularActivityIndicator! {
        didSet {
            loadingIndicator.color = AppTheme.loadingActivityColor()
        }
    }

    private var emailHelper = EmailHelper()
    private var supportWebView: WKWebView!

    var request: URLRequest

    init(url: URL = ServerHelper.asUrl(ServerConstants.Urls.support)) {
        request = URLRequest(url: url)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsHelp
        loadingIndicator.startAnimating()

        setupWebView()

        load()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(doneTapped))

        customRightBtn = UIBarButtonItem(image: UIImage(named: "status_page"), style: .done, target: self, action: #selector(showStatusPage))

        AnalyticsHelper.userGuideOpened()
        Analytics.track(.settingsHelpShown)
    }

    private func setupWebView() {
        supportWebView = WKWebView()

        view.insertSubview(supportWebView, belowSubview: loadingIndicator)
        supportWebView.anchorToAllSidesOf(view: view)

        supportWebView.navigationDelegate = self

        supportWebView.backgroundColor = UIColor.white
        supportWebView.scrollView.backgroundColor = UIColor.white
    }

    deinit {
        supportWebView?.navigationDelegate = nil
    }

    @objc private func doneTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func showStatusPage() {
        let hostingController = UIHostingController(rootView: StatusPageView().setupDefaultEnvironment())
        navigationController?.pushViewController(hostingController, animated: true)
    }

    private func load() {
        supportWebView.load(request)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let urlStr = navigationAction.request.url?.absoluteString, urlStr.contains("mailto") {
            let feedback = urlStr.contains("Feedback")
            AnalyticsHelper.userGuideEmail(feedback: feedback)
            emailHelper.presentSupportDialog(self, feedback: feedback)
            decisionHandler(.cancel)
            return
        } else if let urlStr = navigationAction.request.url?.absoluteString, !urlStr.contains("device=ios"), urlStr.contains("support.pocketcasts.com") {
            let newUrlStr = "\(urlStr)\(urlStr.contains("?") ? "&" : "?")device=ios"
            if let newUrl = URL(string: newUrlStr) {
                let newRequest = URLRequest(url: newUrl)
                webView.load(newRequest)

                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
