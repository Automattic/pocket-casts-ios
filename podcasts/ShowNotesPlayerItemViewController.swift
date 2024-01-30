import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SafariServices
import UIKit
import WebKit

class ShowNotesPlayerItemViewController: PlayerItemViewController, SFSafariViewControllerDelegate, WKNavigationDelegate {
    @IBOutlet var episodeTitle: UILabel!
    @IBOutlet var publishedDate: UILabel!
    @IBOutlet var duration: UILabel!
    @IBOutlet var durationImageView: UIImageView!
    @IBOutlet var dateImageView: UIImageView!

    @IBOutlet var dividerHeight: NSLayoutConstraint! {
        didSet {
            dividerHeight.constant = 1.0 / UIScreen.main.scale
        }
    }

    @IBOutlet var showNotesScrollView: UIScrollView!

    private var downloadingShowNotes = false
    private var lastEpisodeUuidRendered = ""
    private var docController: UIDocumentInteractionController?

    private var showNotesWebView: WKWebView!
    private var safariViewController: SFSafariViewController?

    @IBOutlet var showNotesHolderView: UIView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var showNotesViewHeight: NSLayoutConstraint!

    @IBOutlet var topDivider: ThemeDividerView! {
        didSet {
            topDivider.style = .playerContrast03
        }
    }

    private var episode: Episode?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupWebView()
        updateColors()
    }

    private func setupWebView() {
        showNotesWebView = WKWebView()

        showNotesWebView.translatesAutoresizingMaskIntoConstraints = false
        showNotesHolderView.addSubview(showNotesWebView)
        showNotesWebView.anchorToAllSidesOf(view: showNotesHolderView)

        showNotesWebView.scrollView.indicatorStyle = .white
        showNotesWebView.allowsLinkPreview = true
        showNotesWebView.navigationDelegate = self
        showNotesWebView.scrollView.isDirectionalLockEnabled = true
        showNotesWebView.allowsBackForwardNavigationGestures = true

        showNotesWebView.isOpaque = false
        showNotesWebView.backgroundColor = UIColor.clear
        showNotesWebView.scrollView.backgroundColor = UIColor.clear
    }

    deinit {
        showNotesWebView?.navigationDelegate = nil
    }

    override func willBeAddedToPlayer() {
        updateShowNotes()
        addObservers()
        showNotesScrollView.delegate = scrollViewHandler
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()
        showNotesScrollView.delegate = nil
    }

    override func themeDidChange() {
        updateColors()
    }

    private func addObservers() {
        addCustomObserver(Constants.Notifications.playbackStarting, selector: #selector(updateShowNotes))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(updateShowNotes))
        addCustomObserver(UIApplication.willEnterForegroundNotification, selector: #selector(handleWillEnterForeground))
    }

    @objc private func handleWillEnterForeground() {
        // when there's memory pressure it's possible for the WKWebView to destroy the contents of what's in there and not bring it back, so reload it here
        lastEpisodeUuidRendered = ""
        updateShowNotes()
    }

    @objc private func updateShowNotes() {
        guard let episode = PlaybackManager.shared.currentEpisode() as? Episode else { return }
        self.episode = episode
        let pubDate = DateFormatHelper.sharedHelper.longLocalizedFormat(episode.publishedDate)
        publishedDate.text = pubDate
        duration.text = TimeFormatter.shared.minutesFormatted(time: episode.duration)

        // everything below here is expensive to do every single update, so limit it to when the episode changes
        if lastEpisodeUuidRendered == episode.uuid { return }
        lastEpisodeUuidRendered = episode.uuid
        updateColors()
        episodeTitle.text = episode.displayableTitle()

        loadShowNotes()
    }

    private func updateColors() {
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        episodeTitle.textColor = ThemeColor.playerContrast01()
        dateImageView.tintColor = ThemeColor.playerContrast02()
        durationImageView.tintColor = ThemeColor.playerContrast02()
        duration.textColor = AppTheme.colorForStyle(.playerContrast02)
        publishedDate.textColor = AppTheme.colorForStyle(.playerContrast02)
    }

    // MARK: - Show Notes

    private func loadShowNotes() {
        if downloadingShowNotes { return }

        guard let episode = episode else { return }

        loadingIndicator.startAnimating()

        CacheServerHandler.shared.loadShowNotes(podcastUuid: episode.parentIdentifier(), episodeUuid: episode.uuid, cached: { [weak self] cachedShowNotes in
            self?.downloadingShowNotes = false
            self?.displayShowNotes(cachedShowNotes)
        }) { [weak self] showNotes in
            if let showNotes = showNotes {
                self?.downloadingShowNotes = false
                self?.displayShowNotes(showNotes)

                // if we get back the no show notes available message, make sure next update we try again
                if showNotes == CacheServerHandler.noShowNotesMessage {
                    self?.lastEpisodeUuidRendered = ""
                }
            }
        }
    }

    private func linkTintColor() -> UIColor {
        PlayerColorHelper.playerHighlightColor01(for: Theme.ThemeType.dark)
    }

    private func displayShowNotes(_ showNotes: String?) {
        guard let episode = episode else { return }

        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.loadingIndicator.stopAnimating()
            let tintColor = strongSelf.linkTintColor()
            if let showNotes = showNotes {
                let isCurrentEpisode = PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid)
                let formattedNotes = ShowNotesFormatter.format(showNotes: showNotes, tintColor: tintColor, convertTimesToLinks: isCurrentEpisode, bgColor: nil, textColor: ThemeColor.playerContrast01())
                strongSelf.showNotesWebView.loadHTMLString(formattedNotes, baseURL: URL(fileURLWithPath: Bundle.main.bundlePath))
                // We need to ensure that the scroll view offset is back at 0,0 to cater for instances
                // where the user scrolled the previous show notes
                // See https://github.com/Automattic/pocket-casts-ios/issues/651
                strongSelf.showNotesScrollView.setContentOffset(CGPointZero, animated: false)
            }
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated else {
            decisionHandler(.allow)
            return
        }

        if url.host == "localhost" {
            guard let fragment = url.fragment else {
                decisionHandler(.cancel)
                return
            }

            let components = fragment.components(separatedBy: "=")
            if components.count < 2 {
                decisionHandler(.cancel)
                return
            }

            let timeToSkipTo = SJCommonUtils.colonFormattedString(toTime: components[1])
            if timeToSkipTo >= 0 {
                containerDelegate?.scrollToNowPlaying()
                SwiftUtils.performAfterDelayOnMainThread(0.4, closure: {
                    PlaybackManager.shared.seekTo(time: timeToSkipTo)
                })
            }
        } else if UserDefaults.standard.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            if URLHelper.isValidScheme(url.scheme) {
                safariViewController = SFSafariViewController(with: url)
                safariViewController?.delegate = self

                NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
                SceneHelper.rootViewController()?.present(safariViewController!, animated: true, completion: nil)

                Analytics.track(.playerShowNotesLinkTapped, properties: ["episode_uuid": lastEpisodeUuidRendered])
            } else if URLHelper.isMailtoScheme(url.scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showNotesWebView.evaluateJavaScript("document.readyState", completionHandler: { [weak self] complete, _ in
            guard let _ = complete else { return }

            self?.showNotesWebView.evaluateJavaScript("document.body.offsetHeight", completionHandler: { [weak self] height, _ in
                guard let strongSelf = self, let cgHeight = height as? CGFloat else { return }

                strongSelf.showNotesViewHeight.constant = CGFloat(cgHeight) + Constants.Values.extraShowNotesVerticalSpacing
                strongSelf.view.layoutIfNeeded()

                if strongSelf.showNotesViewHeight.constant + strongSelf.showNotesHolderView.frame.origin.y < strongSelf.view.frame.height {
                    // if the show notes aren't long enough, we need to add the pull down gesture
                    strongSelf.showNotesWebView.scrollView.isScrollEnabled = false
                }
            })
        })
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        safariViewController?.delegate = nil
        safariViewController = nil
    }
}
