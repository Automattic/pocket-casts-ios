import MessageUI
import SwiftUI
import PocketCastsServer
import UIKit
import WebKit

class OnlineSupportController: PCViewController, WKNavigationDelegate, UIAdaptivePresentationControllerDelegate {
    enum Source: String {
        case settings
        case winback
        case about
    }

    @IBOutlet var loadingIndicator: AngularActivityIndicator! {
        didSet {
            loadingIndicator.color = AppTheme.loadingActivityColor()
        }
    }

    private var emailHelper = EmailHelper()
    private var supportWebView: WKWebView!
    private var databaseExport: DatabaseExport? = nil
    private var loadingAlert: ShiftyLoadingAlert?
    private let source: Source

    var didDismiss: (() -> Void)? = nil

    var request: URLRequest

    init(url: URL = ServerHelper.asUrl(ServerConstants.Urls.support), source: Source = .settings) {
        request = URLRequest(url: url)
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presentationController?.delegate = self
        navigationController?.presentationController?.delegate = self

        title = L10n.settingsHelp
        loadingIndicator.startAnimating()

        setupWebView()

        load()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(doneTapped))

        customRightBtn = UIBarButtonItem(image: UIImage(named: "more"), style: .done, target: self, action: #selector(showOptions(_:)))

        AnalyticsHelper.userGuideOpened()

        switch source {
        case .winback:
            Analytics.track(.winbackScreenShown, properties: ["screen": "help_and_feedback"])
        default:
            Analytics.track(.settingsHelpShown)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        switch source {
        case .winback:
            Analytics.track(.winbackScreenDismissed, properties: ["screen": "help_and_feedback"])
        default:
            break
        }
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
        dismiss(animated: true, completion: didDismiss)
    }

    @objc private func showOptions(_ sender: UIBarButtonItem) {
        let controller = UIAlertController()
        controller.popoverPresentationController?.barButtonItem = sender

        controller.addAction(.init(title: L10n.settingsConnectionStatus, style: .default, handler: { [weak self] _ in
            self?.showStatusPage()
        }))

        controller.addAction(.init(title: L10n.exportDatabase, style: .default, handler: { [weak self] _ in
            self?.export(sender)
        }))

        controller.addAction(.init(title: L10n.logs, style: .default, handler: { [weak self] _ in
            self?.viewLogs(sender)
        }))

        controller.addAction(.init(title: L10n.cancel, style: .destructive))

        present(controller, animated: true)
    }

    private func showStatusPage() {
        let hostingController = ThemedHostingController(rootView: StatusPageView(source: source))
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
            emailHelper.presentSupportDialog(self, type: feedback ? .feedback : .support)
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

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismiss?()
    }
}

// MARK: - Export

private extension OnlineSupportController {
    func export(_ sender: UIBarButtonItem) {
        Analytics.track(.exportDatabaseTapped, properties: ["source": source.rawValue])

        databaseExport = .init()

        loadingAlert = ShiftyLoadingAlert(title: L10n.exportingDatabase)
        loadingAlert?.showAlert(self, hasProgress: false, completion: { [weak self] in
            Task {
                let url = await self?.databaseExport?.export()
                self?.shareExport(url: url, sender: sender)
            }
        })
    }

    @MainActor
    func shareExport(url: URL?, sender: UIBarButtonItem) {
        loadingAlert?.hideAlert(false)
        loadingAlert = nil

        guard let url else {
            SJUIUtils.showAlert(title: L10n.settingsExportError, message: nil, from: self)
            return
        }

        // Share the file
        let shareSheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        shareSheet.completionWithItemsHandler = { [weak self] _, _, _, _ in
            // Attempt to cleanup the temporary file
            self?.databaseExport?.cleanup(url: url)
            self?.databaseExport = nil
        }

        shareSheet.popoverPresentationController?.barButtonItem = sender

        present(shareSheet, animated: true, completion: nil)
    }
}

// MARK: - Logs

private extension OnlineSupportController {
    func viewLogs(_ sender: UIBarButtonItem) {
        let vc = LogsViewController(source: source)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
