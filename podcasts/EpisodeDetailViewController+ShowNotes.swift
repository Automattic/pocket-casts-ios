import Foundation
import PocketCastsServer
import PocketCastsUtils
import SafariServices
import WebKit

extension EpisodeDetailViewController: WKNavigationDelegate, SFSafariViewControllerDelegate {
    func setupWebView() {
        showNotesWebView = WKWebView()

        showNotesHolderView.insertSubview(showNotesWebView, belowSubview: loadingIndicator)
        showNotesWebView.translatesAutoresizingMaskIntoConstraints = false

        let showNotesWebViewTopConstraint = showNotesWebView.topAnchor.constraint(equalTo: showNotesHolderView.topAnchor, constant: 20)
        self.showNotesWebViewTopConstraint = showNotesWebViewTopConstraint
        NSLayoutConstraint.activate([
            showNotesWebView.leadingAnchor.constraint(equalTo: showNotesHolderView.leadingAnchor),
            showNotesWebView.trailingAnchor.constraint(equalTo: showNotesHolderView.trailingAnchor),
            showNotesWebView.bottomAnchor.constraint(equalTo: showNotesHolderView.bottomAnchor),
            showNotesWebViewTopConstraint
        ])

        showNotesWebView.allowsLinkPreview = true
        showNotesWebView.navigationDelegate = self
        showNotesWebView.isOpaque = false
        showNotesWebView.backgroundColor = UIColor.clear

        showNotesWebView.scrollView.backgroundColor = UIColor.clear
        showNotesWebView.scrollView.isScrollEnabled = false

        showNotesWebView.scrollView.showsVerticalScrollIndicator = false

        setupTranscriptExcerptView()
    }

    func setupTranscriptExcerptView() {
        let transcriptExcerpt = UIView()
        transcriptExcerpt.backgroundColor = .clear
        transcriptExcerpt.translatesAutoresizingMaskIntoConstraints = false
        transcriptExcerpt.isHidden = true
        mainScrollView.insertSubview(transcriptExcerpt, aboveSubview: showNotesHolderView)

        NSLayoutConstraint.activate([
            transcriptExcerpt.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor),
            transcriptExcerpt.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor),
            transcriptExcerpt.bottomAnchor.constraint(equalTo: showNotesHolderView.topAnchor),
            transcriptExcerpt.heightAnchor.constraint(equalToConstant: 78)
        ])

        self.transcriptExcerpt = transcriptExcerpt
    }

    func loadShowNotes() {
        if downloadingShowNotes { return }

        loadingIndicator.startAnimating()
        hideErrorMessage(hide: true)

        Task { [weak self] in
            guard let self else { return }

            let parentIdentifier = episode.parentIdentifier()
            let episodeUUID = episode.uuid
            let showNotes = try? await ShowInfoCoordinator.shared.loadShowNotes(podcastUuid: parentIdentifier, episodeUuid: episodeUUID)

            if FeatureFlag.episodeDetailTranscript.enabled {
                let hideExcerpt: (EpisodeDetailViewController?) -> Void = { vc in
                    vc?.transcriptExcerpt?.isHidden = true
                    vc?.showNotesHolderTopAnchor?.constant = 0.0
                    vc?.showNotesWebViewTopConstraint?.constant = 20.0
                }
                if let metadata = try? await ShowInfoCoordinator.shared.loadTranscriptsMetadata(podcastUuid: parentIdentifier, episodeUuid: episodeUUID), !metadata.transcripts.isEmpty {
                    let viewModel = TranscriptExcerptViewModel(episodeUUID: episodeUUID, podcastUUID: parentIdentifier, isGeneratedTranscript: metadata.hasGeneratedTranscripts) {
                        DispatchQueue.main.async { [weak self] in
                            let playbackManager = TranscriptEpisodeInfoProvider(episodeUUID: episodeUUID, podcastUUID: parentIdentifier)
                            let controller = TranscriptContainerViewController(playbackManager: playbackManager)
                            controller.playButtonTapped = { [weak self] playing in
                                self?.playPauseEpisode(isPlaying: playing)
                            }
                            self?.present(controller, animated: true)
                        }
                    }
                    await MainActor.run { [weak self] in
                        let view = TranscriptExcerptView(viewModel: viewModel).themedUIView
                        view.translatesAutoresizingMaskIntoConstraints = false
                        self?.transcriptExcerpt?.addSubview(view)
                        view.anchorToAllSidesOf(view: self?.transcriptExcerpt)
                        self?.transcriptExcerpt?.isHidden = false
                        self?.showNotesHolderTopAnchor?.constant = 78.0
                        self?.showNotesWebViewTopConstraint?.constant = 0.0
                    }
                } else {
                    await MainActor.run { [weak self] in
                        hideExcerpt(self)
                    }
                }
            }
            downloadingShowNotes = false
            showNotesDidLoad(showNotes: showNotes ?? CacheServerHandler.noShowNotesMessage)
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
