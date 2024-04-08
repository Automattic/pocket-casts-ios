import Foundation
import PocketCastsServer
import SafariServices
import WebKit
import PocketCastsUtils

extension EpisodeDetailViewController: WKNavigationDelegate, SFSafariViewControllerDelegate {
    func setupWebView() {
        showNotesWebView = WKWebView()

        showNotesHolderView.insertSubview(showNotesWebView, belowSubview: loadingIndicator)
        showNotesWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            showNotesWebView.leadingAnchor.constraint(equalTo: showNotesHolderView.leadingAnchor),
            showNotesWebView.trailingAnchor.constraint(equalTo: showNotesHolderView.trailingAnchor),
            showNotesWebView.bottomAnchor.constraint(equalTo: showNotesHolderView.bottomAnchor),
            showNotesWebView.topAnchor.constraint(equalTo: showNotesHolderView.topAnchor, constant: 20)
        ])

        showNotesWebView.allowsLinkPreview = true
        showNotesWebView.navigationDelegate = self
        showNotesWebView.isOpaque = false
        showNotesWebView.backgroundColor = UIColor.clear

        showNotesWebView.scrollView.backgroundColor = UIColor.clear
        showNotesWebView.scrollView.isScrollEnabled = false

        showNotesWebView.scrollView.showsVerticalScrollIndicator = false
    }

    func loadShowNotes() {
        if downloadingShowNotes { return }

        loadingIndicator.startAnimating()
        hideErrorMessage(hide: true)

        if FeatureFlag.newShowNotesEndpoint.enabled {
            let podcastUUID = episode.parentIdentifier()
            let episodeUUID = episode.uuid
            Task { [weak self] in
                if let showNotes = await self?.episode.loadMetadata()?.showNotes {
                    self?.downloadingShowNotes = false
                    self?.showNotesDidLoad(showNotes: showNotes)
                }
            }
            return
        }

        CacheServerHandler.shared.loadShowNotes(podcastUuid: episode.parentIdentifier(), episodeUuid: episode.uuid, cached: { [weak self] cachedShowNotes in
            self?.downloadingShowNotes = false
            self?.showNotesDidLoad(showNotes: cachedShowNotes)
        }) { [weak self] showNotes in
            if let showNotes = showNotes {
                self?.downloadingShowNotes = false
                self?.showNotesDidLoad(showNotes: showNotes)
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showNotesWebView.evaluateJavaScript("document.readyState", completionHandler: { [weak self] complete, _ in
            guard let _ = complete else { return }

            self?.showNotesWebView.evaluateJavaScript("document.body.offsetHeight", completionHandler: { [weak self] height, _ in
                guard let cgHeight = height as? CGFloat else { return }

                self?.showNotesHolderViewHeight.constant = CGFloat(cgHeight) + Constants.Values.extraShowNotesVerticalSpacing
                self?.view.layoutIfNeeded()
            })
        })
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if Settings.openLinks, let url = navigationAction.request.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else if URLHelper.isValidScheme(navigationAction.request.url?.scheme) {
                safariViewController = navigationAction.request.url.flatMap {
                    SFSafariViewController(with: $0)
                }

                safariViewController?.delegate = self

                NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
                present(safariViewController!, animated: true, completion: nil)

                Analytics.track(.episodeDetailShowNotesLinkTapped, properties: ["episode_uuid": episode.uuid, "source": viewSource])
            } else if let url = navigationAction.request.url, URLHelper.isMailtoScheme(url.scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }

            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        safariViewController?.delegate = nil
        safariViewController = nil
    }

    private func showNotesDidLoad(showNotes: String) {
        rawShowNotes = showNotes
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadingIndicator.stopAnimating()
            strongSelf.renderShowNotes()
        }
    }

    func renderShowNotes() {
        guard let showNotes = rawShowNotes else { return }
        if showNotes == CacheServerHandler.noShowNotesMessage {
            failedToLoadLabel.text = showNotes
            hideErrorMessage(hide: false)
        } else {
            let currentTheme = themeOverride ?? Theme.sharedTheme.activeTheme
            lastThemeRenderedNotesIn = currentTheme
            let formattedNotes = ShowNotesFormatter.format(showNotes: showNotes, tintColor: linkTintColor(), convertTimesToLinks: false, bgColor: ThemeColor.primaryUi01(for: currentTheme), textColor: ThemeColor.primaryText01(for: currentTheme))
            showNotesWebView.loadHTMLString(formattedNotes, baseURL: URL(fileURLWithPath: Bundle.main.bundlePath))
        }
    }

    private func linkTintColor() -> UIColor {
        let currentTheme = themeOverride ?? Theme.sharedTheme.activeTheme

        return ThemeColor.primaryInteractive01(for: currentTheme)
    }
}
