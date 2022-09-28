import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SafariServices
import UIKit
import WebKit

class EpisodeDetailViewController: FakeNavViewController, UIDocumentInteractionControllerDelegate {
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var episodeName: ThemeableLabel!
    
    @IBOutlet var podcastName: UILabel! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(podcastNameTapped))
            podcastName.addGestureRecognizer(tapGesture)
            podcastName.isUserInteractionEnabled = true
        }
    }
    
    @IBOutlet var episodeChevron: UIImageView! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(podcastNameTapped))
            episodeChevron.addGestureRecognizer(tapGesture)
            episodeChevron.isUserInteractionEnabled = true
        }
    }
    
    @IBOutlet var downloadIndicator: AngularProgressIndicator!
    
    @IBOutlet var topDivider: ThemeDividerView!
    @IBOutlet var bottomDivider: ThemeDividerView!
    
    @IBOutlet var showNotesHolderView: UIView!
    @IBOutlet var showNotesHolderViewHeight: NSLayoutConstraint!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet var mainScrollView: UIScrollView! {
        didSet {
            mainScrollView.contentInset = UIEdgeInsets(top: 56, left: 0, bottom: Constants.Values.miniPlayerOffset, right: 0)
            mainScrollView.delegate = self
        }
    }
    
    @IBOutlet var buttonsStackView: UIStackView!
    @IBOutlet var downloadBtn: UIButton!
    @IBOutlet var upNextBtn: UIButton!
    @IBOutlet var playPauseBtn: PlayPauseButton!
    @IBOutlet var playStatusButton: UIButton!
    @IBOutlet var archiveButton: UIButton!
    
    @IBOutlet var episodeDate: ThemeableLabel! {
        didSet {
            episodeDate.style = .primaryText02
        }
    }
    
    @IBOutlet var episodeInfo: ThemeableLabel! {
        didSet {
            episodeInfo.style = .primaryText02
        }
    }
    
    var themeOverride: Theme.ThemeType?
    
    @IBOutlet var progressView: UIView!
    @IBOutlet var progressWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var playPauseBtnWidth: NSLayoutConstraint!
    
    @IBOutlet var messageView: RoundedBorderView! {
        didSet {
            messageView.getBorderColor = { AppTheme.episodeMessageBorderColor(for: self.themeOverride) }
            messageView.getBgColor = { AppTheme.episodeMessageBackgroundColor(for: self.themeOverride) }
        }
    }
    
    @IBOutlet var messageIcon: UIImageView!
    @IBOutlet var messageTitle: ThemeableLabel! {
        didSet {
            messageTitle.style = .primaryText01
        }
    }
    
    @IBOutlet var messageDetails: ThemeableLabel! {
        didSet {
            messageDetails.style = .primaryText02
        }
    }
    
    @IBOutlet var buttonBottomOffsetConstraint: NSLayoutConstraint!
    
    @IBOutlet var failedToLoadLabel: UILabel!
    @IBOutlet var tryAgainButton: UIButton!
    
    private var docController: UIDocumentInteractionController?
    private var starButton: UIButton?
    
    var rawShowNotes: String?
    var lastThemeRenderedNotesIn: Theme.ThemeType?
    var downloadingShowNotes = false
    var showNotesWebView: WKWebView!
    var safariViewController: SFSafariViewController?
    
    var episode: Episode
    var podcast: Podcast

    let viewSource: EpisodeDetailViewSource

    // MARK: - Init
    
    init(episodeUuid: String, source: EpisodeDetailViewSource) {
        // it's ok to crash here, an episode card with no episode or podcast is invalid
        episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid)!
        podcast = DataManager.sharedManager.findPodcast(uuid: episode.podcastUuid, includeUnsubscribed: true)!
        viewSource = source

        super.init(nibName: "EpisodeDetailViewController", bundle: nil)
    }
    
    init(episodeUuid: String, podcast: Podcast, source: EpisodeDetailViewSource) {
        episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid)! // it's ok to crash here, an episode card with no episode is invalid
        self.podcast = podcast
        viewSource = source
        
        super.init(nibName: "EpisodeDetailViewController", bundle: nil)
    }
    
    init(episode: Episode, podcast: Podcast, source: EpisodeDetailViewSource) {
        self.episode = episode
        self.podcast = podcast
        viewSource = source
        
        super.init(nibName: "EpisodeDetailViewController", bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        mainScrollView?.delegate = nil
        showNotesWebView?.navigationDelegate = nil
    }
    
    // MARK: - View
    
    override func viewDidLoad() {
        displayMode = .card
        super.viewDidLoad()

        closeTapped = { [weak self] in
            Analytics.track(.episodeDetailDismissed)
            self?.dismiss(animated: true, completion: nil)
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        
        scrollPointToChangeTitle = episodeName.frame.origin.y + episodeName.bounds.height
        navTitle = episode.title
        addRightAction(image: UIImage(named: "podcast-share"), accessibilityLabel: L10n.share, action: #selector(shareTapped(_:)))
        starButton = addRightAction(image: UIImage(named: "star_empty"), accessibilityLabel: L10n.starEpisode, action: #selector(starTapped(_:)))
        
        setupWebView()
        updateMessageView()
        mainScrollView.contentOffset.y = -100
        
        hideErrorMessage(hide: true)
        Analytics.track(.episodeDetailShown)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateDisplayedData()
        updateColors()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadShowNotes()
        
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(playbackEventDidFire))
        addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(playbackEventDidFire))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(playbackEventDidFire))
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(playbackEventDidFire))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(playbackEventDidFire))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(playbackEventDidFire))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(playbackEventDidFire))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(playbackEventDidFire))
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(playbackProgressDidChange))
        
        addCustomObserver(Constants.Notifications.downloadProgress, selector: #selector(updateDownloadProgress))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(episodeDownloadedEvent))
        
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(specificEpisodeEventDidFire(_:)))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(specificEpisodeEventDidFire(_:)))
        addCustomObserver(Constants.Notifications.episodeDurationChanged, selector: #selector(specificEpisodeEventDidFire(_:)))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(specificEpisodeEventDidFire(_:)))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(specificEpisodeEventDidFire(_:)))
        addCustomObserver(ServerNotifications.episodeTypeOrLengthChanged, selector: #selector(specificEpisodeEventDidFire(_:)))
        
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(generalEpisodeEventDidFire))
        
        AnalyticsHelper.episodeOpened(podcastUuid: episode.podcastUuid, episodeUuid: episode.uuid)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removeAllCustomObservers()
    }
    
    private var lastLayedOutWidth: CGFloat = 0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollPointToChangeTitle = episodeName.frame.origin.y + episodeName.bounds.height
        
        if lastLayedOutWidth != view.bounds.width {
            lastLayedOutWidth = view.bounds.width
            // make the play button smaller on tiny phones and iPad split screen tiny view
            if lastLayedOutWidth <= 320 {
                playPauseBtnWidth.constant = 60
                view.layoutIfNeeded()
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - Event Based Updates
    
    @objc private func specificEpisodeEventDidFire(_ notification: Notification) {
        guard let episodeUuid = notification.object as? String, episodeUuid == episode.uuid else {
            return
        }
        
        updateDisplayedData()
    }
    
    @objc private func playbackEventDidFire() {
        updateDisplayedData()
    }
    
    @objc private func updateDownloadProgress() {
        updateDisplayedData(reloadingEpisode: false)
    }
    
    @objc private func episodeDownloadedEvent() {
        updateDisplayedData()
        updateColors()
    }
    
    @objc private func generalEpisodeEventDidFire() {
        updateDisplayedData()
    }
    
    // MARK: - Update Display
    
    func updateDisplayedData(reloadingEpisode: Bool = true) {
        if Thread.isMainThread {
            performUpdateDisplayedData(reloadingEpisode: reloadingEpisode)
        }
        else {
            DispatchQueue.main.sync { [weak self] in
                guard let self = self else { return }
                
                self.performUpdateDisplayedData(reloadingEpisode: reloadingEpisode)
            }
        }
    }
    
    private func performUpdateDisplayedData(reloadingEpisode: Bool = true) {
        if reloadingEpisode {
            guard let updatedEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid) else { return }
            episode = updatedEpisode
        }
        
        if episode.downloading() || episode.queued() || episode.waitingForWifi() {
            if downloadIndicator.isHidden { downloadIndicator.isHidden = false }
            
            if episode.waitingForWifi() {
                downloadBtn.setTitle(L10n.cancel, for: .normal)
                downloadIndicator.progress = 1
                downloadIndicator.color = ThemeColor.secondaryIcon01(for: themeOverride)
            }
            else if let progress = DownloadManager.shared.progressManager.progressForEpisode(episode.uuid) {
                downloadBtn.setTitle(progress.percentageProgressAsString(), for: .normal)
                downloadIndicator.progress = CGFloat(progress.progress())
            }
            else {
                downloadBtn.setTitle(L10n.podcastDetailsQueued, for: .normal)
                downloadIndicator.progress = 0.1
            }
        }
        else {
            if !downloadIndicator.isHidden { downloadIndicator.isHidden = true }
        }
        
        episodeName.text = episode.displayableTitle()
        podcastName.text = podcast.title
        if let uuid = episode.parentPodcast()?.uuid {
            podcastImage.setPodcast(uuid: uuid, size: .page)
        }
        
        episodeDate.text = DateFormatHelper.sharedHelper.longLocalizedFormat(episode.publishedDate)
        episodeInfo.text = episode.displayableTimeLeft()
        
        let starImageName = episode.keepEpisode ? "star_filled" : "star_empty"
        starButton?.setImage(UIImage(named: starImageName), for: .normal)
        starButton?.accessibilityLabel = episode.keepEpisode ? L10n.statusStarred : L10n.statusNotStarred
        starButton?.accessibilityHint = episode.keepEpisode ? L10n.accessibilityHintUnstar : L10n.accessibilityHintStar
        
        updateButtonStates()
        updateProgress()
        updateMessageView()
    }
    
    @objc private func playbackProgressDidChange() {
        updateProgress()
    }
    
    override func handleThemeChanged() {
        updateColors()
    }
    
    func updateColors() {
        episodeDate.themeOverride = themeOverride
        episodeInfo.themeOverride = themeOverride
        topDivider.themeOverride = themeOverride
        bottomDivider.themeOverride = themeOverride
        episodeName.themeOverride = themeOverride
        
        let bgColor = ThemeColor.primaryUi01(for: themeOverride)
        showNotesWebView.backgroundColor = bgColor
        view.backgroundColor = bgColor
        
        let podcastColor = (themeOverride?.isDark ?? Theme.isDarkTheme()) ? ColorManager.darkThemeTintForPodcast(podcast) : ColorManager.lightThemeTintForPodcast(podcast)
        podcastName.textColor = ThemeColor.podcastText02(podcastColor: podcastColor, for: themeOverride)
        episodeChevron.tintColor = ThemeColor.podcastIcon02(podcastColor: podcastColor, for: themeOverride)
        progressView.backgroundColor = ThemeColor.podcastIcon02(podcastColor: podcastColor, for: themeOverride)
        loadingIndicator.color = ThemeColor.podcastIcon02(podcastColor: podcastColor, for: themeOverride)
        
        let actionColor = podcast.iconTintColor(for: themeOverride)
        downloadBtn.tintColor = episode.downloaded(pathFinder: DownloadManager.shared) ? AppTheme.successGreen() : actionColor
        upNextBtn.tintColor = actionColor
        playPauseBtn.circleColor = actionColor
        playPauseBtn.playButtonColor = bgColor
        playStatusButton.tintColor = actionColor
        archiveButton.tintColor = actionColor
        downloadIndicator.color = episode.waitingForWifi() ? ThemeColor.secondaryIcon01(for: themeOverride) : actionColor
        
        let primaryText02 = ThemeColor.primaryText02(for: themeOverride)
        downloadBtn.setTitleColor(primaryText02, for: .normal)
        upNextBtn.setTitleColor(primaryText02, for: .normal)
        playStatusButton.setTitleColor(primaryText02, for: .normal)
        archiveButton.setTitleColor(primaryText02, for: .normal)
        
        messageIcon.tintColor = primaryText02
        
        if lastThemeRenderedNotesIn != (themeOverride ?? Theme.sharedTheme.activeTheme) {
            renderShowNotes()
        }
        
        updateButtonStates()
        updateNavColors(bgColor: bgColor, titleColor: ThemeColor.secondaryText01(for: themeOverride), buttonColor: actionColor)
    }
    
    @objc private func starTapped(_ sender: UIButton) {
        EpisodeManager.setStarred(!episode.keepEpisode, episode: episode, updateSyncStatus: SyncManager.isUserLoggedIn())
    }
    
    // MARK: - Sharing
    
    @objc private func shareTapped(_ sender: UIButton) {
        let shareOptions = OptionsPicker(title: nil)
        
        let sourceRect = sender.superview!.convert(sender.frame, to: view)
        let shareLinkAction = OptionAction(label: L10n.podcastShareEpisode, icon: nil) { [weak self] in
            self?.shareLinkToEpisode(sharePosition: false, sourceRect: sourceRect)
        }
        shareOptions.addAction(action: shareLinkAction)
        
        let sharePositionAction = OptionAction(label: L10n.shareCurrentPosition, icon: nil) { [weak self] in
            self?.shareLinkToEpisode(sharePosition: true, sourceRect: sourceRect)
        }
        shareOptions.addAction(action: sharePositionAction)
        
        if episode.downloaded(pathFinder: DownloadManager.shared) {
            let openFileAction = OptionAction(label: L10n.podcastShareOpenFile, icon: nil) { [weak self] in
                self?.shareEpisodeFile(sourceRect: sourceRect)
            }
            shareOptions.addAction(action: openFileAction)
        }
        
        shareOptions.show(statusBarStyle: preferredStatusBarStyle)
    }
    
    @objc private func podcastNameTapped() {
        guard let podcast = episode.parentPodcast() else { return }

        Analytics.track(.episodeDetailPodcastNameTapped)

        dismiss(animated: true) {
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
        }
    }
    
    // MARK: - Orientation
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
    
    // MARK: - UIDocumentInteractionControllerDelegate
    
    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        docController = nil
    }
    
    private func shareLinkToEpisode(sharePosition: Bool, sourceRect: CGRect) {
        let shareTime = sharePosition ? episode.playedUpTo : 0

        let type = shareTime == 0 ? "episode" : "current_position"
        Analytics.track(.podcastShared, properties: ["type": type, "source": playbackSource])

        SharingHelper.shared.shareLinkTo(episode: episode, shareTime: shareTime, fromController: self, sourceRect: sourceRect, sourceView: view)
    }
    
    private func shareEpisodeFile(sourceRect: CGRect) {
        let fileUrl = URL(fileURLWithPath: episode.pathToDownloadedFile(pathFinder: DownloadManager.shared))
        docController = UIDocumentInteractionController(url: fileUrl)
        docController?.name = episode.displayableTitle()
        docController?.delegate = self

        Analytics.track(.podcastShared, properties: ["type": "episode_file", "source": playbackSource])

        let canOpen = docController?.presentOpenInMenu(from: sourceRect, in: view, animated: true) ?? false
        if !canOpen {
            let alert = UIAlertController(title: L10n.error, message: L10n.podcastShareEpisodeErrorMsg, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: L10n.ok, style: UIAlertAction.Style.cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
            docController?.delegate = nil
            docController = nil
        }
    }
    
    // MARK: - Show notes error handling
    
    @IBAction func reloadShowNotes(_ sender: Any) {
        loadShowNotes()
    }
    
    func hideErrorMessage(hide: Bool) {
        tryAgainButton.isHidden = hide
        failedToLoadLabel.isHidden = hide
    }
}

// MARK: - Analytics

extension EpisodeDetailViewController: PlaybackSource {
    var playbackSource: String {
        "episode_detail"
    }
}

enum EpisodeDetailViewSource: String, AnalyticsDescribable {
    case discover
    case downloads
    case listeningHistory = "listening_history"
    case homeScreenWidget = "home_screen_widget"
    case filters
    case podcastScreen = "podcast_screen"
    case starred
    case upNext = "up_next"

    var analyticsDescription: String { rawValue }
}
