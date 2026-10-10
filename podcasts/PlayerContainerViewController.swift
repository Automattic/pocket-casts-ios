import PocketCastsUtils
import UIKit

class PlayerContainerViewController: SimpleNotificationsViewController, PlayerTabDelegate, PlayerItemContainerDelegate {
    @IBOutlet var headerView: UIView!
    @IBOutlet var tabsView: PlayerTabsView! {
        didSet {
            tabsView.setup()
            tabsView.tabDelegate = self
        }
    }

    #if APPCLIP
    @IBOutlet var upNextBtn: UIButton!
    #else
    @IBOutlet var upNextBtn: UpNextButton! {
        didSet {
            upNextBtn.themeOverride = .dark
            upNextBtn.iconColor = AppTheme.colorForStyle(.playerContrast01)
        }
    }
    #endif

    @IBOutlet var mainScrollView: RegionCancellingScrollView! {
        didSet {
            // The player tabs are a spatial carousel, not text, so keep the paging
            // left-to-right in every language. Otherwise UIKit mirrors the scroll
            // view under RTL and the index-based paging math (offset == index * width)
            // opens the last tab (Bookmarks) instead of Now Playing. See #1952.
            mainScrollView.semanticContentAttribute = .forceLeftToRight
            mainScrollView.contentInsetAdjustmentBehavior = .never

            // We don't need to handle the scroll view because it is not dismissable in App Clip
            #if !APPCLIP
            mainScrollView.delegate = self
            #endif
        }
    }

    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var transcriptContainerView: UIView!

    /// Whether the player uses the large screen layout: Now Playing and the tabs side by side
    /// in a `UIArrangementViewController` when there's room, over a blurred artwork background.
    let usesLargeScreenLayout = PlayerContainerViewController.isLargeScreenLayoutAvailable

    static var isLargeScreenLayoutAvailable: Bool {
        #if APPCLIP
        return false
        #else
        guard FeatureFlag.largeScreenNowPlaying.enabled else { return false }
        if #available(iOS 27.1, *) {
            return true
        }
        return false
        #endif
    }

    /// The largest text size of the transcript and the chapters in the large screen layout.
    static let largeScreenMaximumContentSizeCategory = UIContentSizeCategory.accessibilityExtraLarge

    #if !APPCLIP
    /// The `PlayerLargeScreenLayout` when `usesLargeScreenLayout` is on.
    var largeScreenLayoutStorage: AnyObject?
    #endif

    lazy var nowPlayingItem: NowPlayingPlayerItemViewController = {
        let item = NowPlayingPlayerItemViewController()
        item.containerDelegate = self
        item.usesLargeScreenStyle = usesLargeScreenLayout
        item.view.translatesAutoresizingMaskIntoConstraints = false

        return item
    }()

    #if !APPCLIP
    lazy var showNotesItem: ShowNotesPlayerItemViewController = {
        let item = ShowNotesPlayerItemViewController()
        item.scrollViewHandler = self
        item.containerDelegate = self
        item.view.translatesAutoresizingMaskIntoConstraints = false

        return item
    }()

    lazy var chaptersItem: ChaptersViewController = {
        let item = ChaptersViewController()
        item.scrollViewHandler = self
        item.containerDelegate = self
        item.view.translatesAutoresizingMaskIntoConstraints = false
        if usesLargeScreenLayout {
            item.view.maximumContentSizeCategory = Self.largeScreenMaximumContentSizeCategory
        }

        return item
    }()

    lazy var bookmarksItem: BookmarksPlayerTabController = {
        let playbackManager = PlaybackManager.shared
        let bookmarkManager = playbackManager.bookmarkManager
        let item = BookmarksPlayerTabController(bookmarkManager: bookmarkManager,
                                                playbackManager: playbackManager)

        item.view.translatesAutoresizingMaskIntoConstraints = false
        item.containerDelegate = self
        return item
    }()

    lazy var transcriptsItem: TranscriptViewController = {
        let playbackManager = PlaybackManager.shared
        let item = TranscriptViewController(playbackManager: playbackManager)

        item.view.translatesAutoresizingMaskIntoConstraints = false
        if usesLargeScreenLayout {
            item.view.maximumContentSizeCategory = Self.largeScreenMaximumContentSizeCategory
        }
        item.scrollViewHandler = self
        item.containerDelegate = self
        return item
    }()

    private lazy var generatedTranscriptsPremiumOverlay: GeneratedTranscriptsPremiumOverlay = {
        let playbackManager = PlaybackManager.shared
        let item = GeneratedTranscriptsPremiumOverlay(playbackManager: playbackManager)
        item.view.translatesAutoresizingMaskIntoConstraints = false
        item.dismissTranscript = { [weak self] in
            self?.dismissGeneratedTranscriptsPremiumOverlay(dismissTranscript: true)
        }
        item.purchaseSuccessfull = { [weak self] in
            self?.dismissGeneratedTranscriptsPremiumOverlay(dismissTranscript: false)
        }
        return item
    }()

    private lazy var upNextViewController = UpNextViewController(source: .player)
    #endif

    @IBOutlet var closeBtn: ThemeableUIButton! {
        didSet {
            closeBtn.style = .playerContrast02
        }
    }

    var initialTouchPoint = CGPoint.zero

    /// The inner vertical scroll view (if any) under the touch when the dismiss
    /// pan began. Its `bounces` is forced off while the gesture is active so it
    /// can't bounce or scroll alongside the container drag.
    weak var activeInnerScrollView: UIScrollView?
    var savedInnerScrollViewBounces = true

    var showingChapters = false
    var showingNotes = false
    var showingBookmarks = false

    var finalScrollViewConstraint: NSLayoutConstraint?

    /// The velocity in which the player was dismissed
    var dismissVelocity: CGFloat = 0

    /// The final yPosition when dismissing
    var finalYPositionWhenDismissing: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityViewIsModal = true
        setupPlayer()
        setupGestures()
        setupObservers()
        update()

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)

        // To avoid weird animations when apearing, we add the transcript view here
        #if !APPCLIP
        configureTranscriptView()
        #endif
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if !APPCLIP
        showNotesItem.updateScrollSize()
#endif
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        #if !APPCLIP
        if nowPlayingItem.displayTranscript {
            transcriptsItem.didDisappear()
            generatedTranscriptsPremiumOverlay.didDisappear()
        }
        if #available(iOS 27.1, *) {
            largeScreenViewDidDisappear()
        }
        #endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        adjustHeaderConstraintIfNeeded()
        #if !APPCLIP
        if #available(iOS 27.1, *) {
            updateLargeScreenLayoutIfNeeded()
        }
        #endif
        adjustPlayerNoSlidingRegion()
    }

    @IBAction func upNextTapped(_ sender: Any) {
        showUpNext()
    }

    @IBAction func closeTapped(_ sender: Any) {
        #if APPCLIP
        // Close doesn't exist in the App Clip
        #else
        appDelegate()?.miniPlayer()?.closeFullScreenPlayer()
        #endif
    }

    @objc private func showUpNext() {
        #if APPCLIP
        //TODO: Show install banner
        #else
        let navController = SJUIUtils.navController(for: upNextViewController, iconStyle: .secondaryText01, themeOverride: upNextViewController.themeOverride)
        present(navController, animated: true, completion: nil)
        #endif
    }

    // MARK: - Orientation

    // we implement this here to lock all views (except presented modal VCs to portrait)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // We're presented with a custom presentation, so UIKit asks us rather than the video player
        if let videoViewController = presentedViewController as? VideoViewController {
            return videoViewController.supportedInterfaceOrientations
        }

        return .portrait
    }

    // MARK: - PlayerItemContainerDelegate

    func scrollToCurrentChapter() {
        guard scroll(to: .chapters) else {
            return
        }

        #if !APPCLIP
        chaptersItem.scrollToCurrentlyPlayingChapter(animated: false)
        #endif
    }

    func scrollToNowPlaying() {
        scroll(to: .nowPlaying)
    }

    func scrollToBookmarks() {
        scroll(to: .bookmarks)
    }

    func navigateToPodcast() {
        guard let podcast = PlaybackManager.shared.currentPodcast else {
            return
        }

        #if APPCLIP
        //TODO: Show install banner
        #else
        NavigationManager.shared.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast, NavigationManager.podcastSourceKey: PodcastScreenSource.player])
        #endif
    }

    func dismissTranscript() {
        nowPlayingItem.displayTranscript = false
    }

    /// Selects the transcript tab, which only exists next to Now Playing in the large screen
    /// layout. Returns `false` when there's no such tab.
    func showTranscriptTab() -> Bool {
        guard let index = tabsView.tabs.firstIndex(of: .transcript) else { return false }
        didSwitchToTab(index: index)
        return true
    }

    // MARK: - PlayerTabDelegate

    func didSwitchToTab(index: Int) {
        scroll(to: index)
    }

    private func setupObservers() {
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(playbackFinished))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(update))
        addCustomObserver(Constants.Notifications.podcastChaptersDidUpdate, selector: #selector(update))
        addCustomObserver(Constants.Notifications.themeChanged, selector: #selector(themeDidChange))
    }

    private func setupGestures() {
        #if !APPCLIP
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        // Make the horizontal page swipe wait for the dismiss pan to either begin or
        // fail, so a downward-diagonal swipe dismisses the player instead of being
        // captured by the tab scroll view.
        mainScrollView.panGestureRecognizer.require(toFail: panGesture)
        #endif
    }

    @objc private func themeDidChange() {
        updateColors()
        tabsView.themeDidChange()
        nowPlayingItem.themeDidChange()
        #if !APPCLIP
        chaptersItem.themeDidChange()
        showNotesItem.themeDidChange()
        transcriptsItem.themeDidChange()
        #endif
    }

    @objc private func playbackFinished() {
        if PlaybackManager.shared.currentEpisode == nil {
            closeNowPlaying()
        }
    }

    func closeNowPlaying() {
        #if APPCLIP
        //TODO: Show install banner
        #else
        appDelegate()?.miniPlayer()?.closeFullScreenPlayer()
        #endif
    }

    private func setupPlayer() {
        #if !APPCLIP
        if #available(iOS 27.1, *), usesLargeScreenLayout {
            setUpLargeScreenLayout()
            return
        }
        #endif

        nowPlayingItem.willBeAddedToPlayer()
        mainScrollView.addSubview(nowPlayingItem.view)
        addChild(nowPlayingItem)

        let finalConstraint = nowPlayingItem.view.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor)
        NSLayoutConstraint.activate([
            nowPlayingItem.view.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor),
            nowPlayingItem.view.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
            nowPlayingItem.view.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
            nowPlayingItem.view.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
            nowPlayingItem.view.heightAnchor.constraint(equalTo: mainScrollView.heightAnchor),
            finalConstraint
        ])
        finalScrollViewConstraint = finalConstraint

        tabsView.tabs = [.nowPlaying]
    }

    private func adjustHeaderConstraintIfNeeded() {
        guard let window = view.window else { return }

        let requiredHeight = 50 + window.safeAreaInsets.top

        if headerHeightConstraint.constant != requiredHeight {
            headerHeightConstraint.constant = requiredHeight
        }
    }

    /// Whether the Now Playing page is on screen: always next to the tabs in the large screen
    /// split, otherwise only while its tab is selected.
    var isNowPlayingVisible: Bool {
        #if !APPCLIP
        if #available(iOS 27.1, *), isShowingLargeScreenSplit {
            return true
        }
        #endif
        return tabsView.currentTab == 0
    }

    func adjustPlayerNoSlidingRegion() {
        if tabsView.tabs[safe: tabsView.currentTab] == .nowPlaying {
            let sliderRegion = mainScrollView.convert(nowPlayingItem.timeSlider.frame, from: nowPlayingItem.timeSlider.superview)
            // the slider has a large region for the popup that you get when interacting with it, which we don't need to block off (hence the 30pt top offset), and since fingers are imprecise we go 20pt lower too
            let adjustedRegion = sliderRegion.inset(by: UIEdgeInsets(top: 30, left: -10, bottom: -20, right: -10))
            mainScrollView.regionsToCancelIn = adjustedRegion
        } else {
            mainScrollView.regionsToCancelIn = nil
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    // MARK: - App Backgrounding

    @objc func handleAppWillBecomeActive() {
        didSwitchToTab(index: tabsView.currentTab)
    }

    // MARK: - Hide/Show tabs

    func scrollView(isEnabled: Bool) {
        var isEnabled = isEnabled
        #if !APPCLIP
        if #available(iOS 27.1, *), isShowingLargeScreenSplit {
            // The transcript only covers Now Playing, so the tabs next to it keep paging.
            isEnabled = true
        }
        #endif
        mainScrollView.isScrollEnabled = isEnabled
        view.layoutIfNeeded()
    }

    // MARK: - Transcripts

    #if !APPCLIP
    func showTranscript() {
        var transcriptParent: UIViewController = self
        if #available(iOS 27.1, *), let largeScreenTranscriptParent {
            transcriptParent = largeScreenTranscriptParent
        }
        transcriptParent.addChild(transcriptsItem)
        transcriptContainerView.addSubview(transcriptsItem.view)
        transcriptsItem.view.anchorToAllSidesOf(view: transcriptContainerView)
        transcriptsItem.didMove(toParent: transcriptParent)
        transcriptsItem.willBeAddedToPlayer()
        transcriptsItem.themeDidChange()
        transcriptsItem.showGeneratedTranscriptsPremiumOverlay = { [weak self] in
            UIView.animate(withDuration: 0.25) {
                self?.showGeneratedTranscriptsPremiumOverlay()
            }
        }
    }

    private func showGeneratedTranscriptsPremiumOverlay() {
        generatedTranscriptsPremiumOverlay.didAppear()
        addChild(generatedTranscriptsPremiumOverlay)
        view.addSubview(generatedTranscriptsPremiumOverlay.view)
        generatedTranscriptsPremiumOverlay.view.anchorToAllSidesOf(view: view)
        generatedTranscriptsPremiumOverlay.didMove(toParent: self)
    }

    private func dismissGeneratedTranscriptsPremiumOverlay(dismissTranscript: Bool) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.generatedTranscriptsPremiumOverlay.didDisappear()
            self?.generatedTranscriptsPremiumOverlay.willMove(toParent: nil)
            self?.generatedTranscriptsPremiumOverlay.removeFromParent()
            self?.generatedTranscriptsPremiumOverlay.view.removeFromSuperview()
        } completion: { [weak self] _ in
            if dismissTranscript {
                self?.dismissTranscript()
            }
        }
    }

    func hideTranscript() {
        transcriptsItem.willBeRemovedFromPlayer()
        transcriptsItem.willMove(toParent: nil)
        transcriptsItem.removeFromParent()
        transcriptsItem.view.removeFromSuperview()
        transcriptsItem.didDisappear()
    }

    private func configureTranscriptView() {
        transcriptContainerView.bottomAnchor.constraint(equalTo: nowPlayingItem.bottomControlsStackView.topAnchor).isActive = true
        transcriptContainerView.backgroundColor = PlayerColorHelper.playerBackgroundColor01()

        transcriptContainerView.addSubview(transcriptsItem.view)
        transcriptsItem.view.anchorToAllSidesOf(view: transcriptContainerView)
    }
    #endif
}

private extension PlayerContainerViewController {
    @discardableResult
    func scroll(to tab: PlayerTabs) -> Bool {
        guard let index = tabsView.tabs.firstIndex(of: tab) else {
            return false
        }

        scroll(to: index)

        return true
    }

    func scroll(to index: Int) {
        if tabsView.currentTab != index {
            tabsView.currentTab = index
        }
        #if !APPCLIP
        if #available(iOS 27.1, *) {
            rememberLargeScreenTab()
        }
        #endif

        let offset = CGFloat(index) * mainScrollView.frame.width

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [.allowUserInteraction]) {
            self.mainScrollView.setContentOffset(.init(x: offset, y: 0), animated: false)
        }
    }
}

extension PlayerContainerViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .player
    }
}
