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

    @IBOutlet var upNextBtn: UpNextButton! {
        didSet {
            upNextBtn.themeOverride = .dark
            upNextBtn.iconColor = AppTheme.colorForStyle(.playerContrast01)
        }
    }

    @IBOutlet var mainScrollView: RegionCancellingScrollView! {
        didSet {
            mainScrollView.delegate = self
        }
    }

    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!

    lazy var nowPlayingItem: NowPlayingPlayerItemViewController = {
        let item = NowPlayingPlayerItemViewController()
        item.containerDelegate = self
        item.view.translatesAutoresizingMaskIntoConstraints = false

        return item
    }()

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

        return item
    }()

    lazy var bookmarksItem: BookmarksPlayerTabController = {
        let item = BookmarksPlayerTabController()
        item.view.translatesAutoresizingMaskIntoConstraints = false

        return item
    }()

    private lazy var upNextViewController = UpNextViewController(source: .player)

    @IBOutlet var closeBtn: ThemeableUIButton! {
        didSet {
            closeBtn.style = .playerContrast02
        }
    }

    var initialTouchPoint = CGPoint(x: 0, y: 0)

    var showingChapters = false
    var showingNotes = false
    var showingBookmarks = false

    var finalScrollViewConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityViewIsModal = true
        setupPlayer()
        setupGestures()
        setupObservers()
        update()

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.track(.playerShown)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Analytics.track(.playerDismissed)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        adjustHeaderConstraintIfNeeded()
        adjustPlayerNoSlidingRegion()
    }

    @IBAction func upNextTapped(_ sender: Any) {
        showUpNext()
    }

    @IBAction func closeTapped(_ sender: Any) {
        appDelegate()?.miniPlayer()?.closeFullScreenPlayer()
    }

    @objc private func showUpNext() {
        let navController = SJUIUtils.navController(for: upNextViewController, navStyle: .secondaryUi01, titleStyle: .playerContrast01, iconStyle: .playerContrast01, themeOverride: .dark)
        present(navController, animated: true, completion: nil)
    }

    // MARK: - PlayerItemContainerDelegate

    func scrollToCurrentChapter() {
        guard let chapterTabIndex = tabsView.tabs.firstIndex(of: .chapters) else { return }

        tabsView.currentTab = chapterTabIndex
        let scrollRect = CGRect(x: CGFloat(chapterTabIndex) * mainScrollView.frame.width, y: 0, width: mainScrollView.frame.width, height: mainScrollView.frame.height)
        mainScrollView.scrollRectToVisible(scrollRect, animated: true)

        chaptersItem.scrollToCurrentlyPlayingChapter(animated: false)
    }

    func scrollToNowPlaying() {
        tabsView.currentTab = 0
        let scrollRect = CGRect(x: 0, y: 0, width: mainScrollView.frame.width, height: mainScrollView.frame.height)
        mainScrollView.scrollRectToVisible(scrollRect, animated: true)
    }

    // MARK: - PlayerTabDelegate

    func didSwitchToTab(index: Int) {
        let scrollWidth = mainScrollView.bounds.width
        mainScrollView.setContentOffset(CGPoint(x: CGFloat(index) * scrollWidth, y: 0), animated: true)
    }

    private func setupObservers() {
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(playbackFinished))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(update))
        addCustomObserver(Constants.Notifications.podcastChaptersDidUpdate, selector: #selector(update))
        addCustomObserver(Constants.Notifications.themeChanged, selector: #selector(themeDidChange))
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
        panGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(panGesture)
    }

    @objc private func themeDidChange() {
        updateColors()
        tabsView.themeDidChange()
        nowPlayingItem.themeDidChange()
        chaptersItem.themeDidChange()
        showNotesItem.themeDidChange()
    }

    @objc private func playbackFinished() {
        if PlaybackManager.shared.currentEpisode() == nil {
            closeNowPlaying()
        }
    }

    func closeNowPlaying() {
        appDelegate()?.miniPlayer()?.closeFullScreenPlayer()
    }

    private func setupPlayer() {
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

        let requiredHeight = 45 + UIUtil.statusBarHeight(in: window)

        if headerHeightConstraint.constant != requiredHeight {
            headerHeightConstraint.constant = requiredHeight
        }
    }

    func adjustPlayerNoSlidingRegion() {
        if tabsView.currentTab == 0 {
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

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    // MARK: - App Backgrounding

    @objc func handleAppWillBecomeActive() {
        didSwitchToTab(index: tabsView.currentTab)
    }
}
