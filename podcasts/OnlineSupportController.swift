import MessageUI
import SwiftUI
import PocketCastsServer
import PocketCastsUtils
import UIKit
import WebKit

class OnlineSupportController: PCViewController, WKNavigationDelegate, UIAdaptivePresentationControllerDelegate {
    enum Source: String {
        case settings
        case winback
        case about
    }

    private let loadingIndicator = AngularActivityIndicator(size: CGSize(width: 40, height: 40), lineWidth: 2.0, duration: 1.0)

    private var emailHelper = EmailHelper()
    private var supportWebView = WKWebView()
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

        view.backgroundColor = .white

        presentationController?.delegate = self
        navigationController?.presentationController?.delegate = self

        title = L10n.settingsHelp

        // A temporary workaround until the web supports safe area.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance

        setupLoadingIndicator()
        setupWebView()

        loadingIndicator.startAnimating()
        load()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.close, target: self, action: #selector(doneTapped))

        customRightBtn = UIBarButtonItem(image: UIImage(named: "more"), menu: makeOptionsMenu())

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

    private func setupLoadingIndicator() {
        loadingIndicator.color = AppTheme.loadingActivityColor()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.widthAnchor.constraint(equalToConstant: 40),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 40),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40)
        ])
    }

    private func setupWebView() {
        view.insertSubview(supportWebView, belowSubview: loadingIndicator)
        supportWebView.anchorToAllSidesOf(view: view)

        supportWebView.navigationDelegate = self

        supportWebView.backgroundColor = UIColor.white
        supportWebView.scrollView.backgroundColor = UIColor.white
    }

    deinit {
        supportWebView.navigationDelegate = nil
    }

    @objc private func doneTapped() {
        dismiss(animated: true, completion: didDismiss)
    }

    private func makeOptionsMenu() -> UIMenu {
        UIMenu(children: [
            UIAction(title: L10n.settingsConnectionStatus) { [weak self] _ in
                self?.showStatusPage()
            },
            FeatureFlag.troubleshooting.enabled ? UIAction(title: L10n.troubleshootingTitle) { [weak self] _ in
                self?.showTroubleshooting()
            } : nil,
            UIAction(title: L10n.exportDatabase) { [weak self] _ in
                guard let self, let sender = customRightBtn else { return }
                export(sender)
            },
            UIAction(title: L10n.logs) { [weak self] _ in
                guard let self, let sender = customRightBtn else { return }
                viewLogs(sender)
            },
        ].compactMap { $0 })
    }

    private func showStatusPage() {
        let hostingController = ThemedHostingController(rootView: StatusPageView(source: source))
        navigationController?.pushViewController(hostingController, animated: true)
    }

    private func showTroubleshooting() {
        let hostingController = ThemedHostingController(rootView: TroubleshootingView(source: source))
        navigationController?.pushViewController(hostingController, animated: true)
    }

    private func load() {
        supportWebView.load(request)
    }

    override func contentScrollView(for edge: NSDirectionalRectEdge) -> UIScrollView? {
        supportWebView.scrollView
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let urlStr = navigationAction.request.url?.absoluteString, urlStr.contains("mailto") {
            let feedback = urlStr.contains("Feedback")
            let chatbot = urlStr.lowercased().contains("chatbot-support@pocketcasts.com")
            AnalyticsHelper.userGuideEmail(feedback: feedback)
            let type: ZDType = chatbot ? .chatbotSupport : (feedback ? .feedback : .support)
            emailHelper.presentSupportDialog(self, type: type)
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
