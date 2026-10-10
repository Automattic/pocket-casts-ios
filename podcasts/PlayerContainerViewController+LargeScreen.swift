import PocketCastsDataModel
import PocketCastsUtils
import UIKit

/// The large screen player layout (`FeatureFlag.largeScreenNowPlaying`): Now Playing is the
/// primary view of a `UIArrangementViewController` and the tabs are the secondary one. When the
/// arrangement has room, they're side by side. Otherwise it only shows the primary view, which
/// then hosts the regular paged player with Now Playing as its first tab.
@available(iOS 27.1, *)
final class PlayerLargeScreenLayout {
    let arrangementController = UIArrangementViewController()
    let playerPane = PlayerArrangementPaneViewController()
    let tabsPane = PlayerArrangementPaneViewController()
    let background = PlayerArtworkBackgroundView()
    let grabber = PlayerGrabberView()
    let divider = UIView()

    /// Whether the tabs are next to Now Playing rather than paged after it.
    var isSplit = false
    var horizontalSizeClass: UIUserInterfaceSizeClass?
    var constraints: [NSLayoutConstraint] = []

    /// The transcript as the first tab when the tabs are next to Now Playing. When they're
    /// paged, the transcript covers Now Playing instead (`transcriptsItem`).
    var transcriptTab: TranscriptViewController?
    var transcriptPaywall: GeneratedTranscriptsPremiumOverlay?
    var showingTranscript = false
    var transcriptAvailability: (episodeUuid: String, isAvailable: Bool)?
}

@available(iOS 27.1, *)
extension PlayerContainerViewController {
    private var largeScreenLayout: PlayerLargeScreenLayout? {
        largeScreenLayoutStorage as? PlayerLargeScreenLayout
    }

    var isShowingLargeScreenSplit: Bool {
        largeScreenLayout?.isSplit == true
    }

    var largeScreenGrabber: UIView? {
        largeScreenLayout?.grabber
    }

    /// The pane that shows the transcript, which has to be its parent.
    var largeScreenTranscriptParent: UIViewController? {
        largeScreenLayout?.playerPane
    }

    func setUpLargeScreenLayout() {
        let layout = PlayerLargeScreenLayout()
        largeScreenLayoutStorage = layout

        layout.background.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(layout.background, at: 0)
        layout.background.anchorToAllSidesOf(view: view)

        let arrangementController = layout.arrangementController
        arrangementController.setViewController(layout.playerPane, for: .primary)
        arrangementController.setViewController(layout.tabsPane, for: .secondary)
        var arrangement = UISplitArrangement().axes(.horizontal)
        var playerProperties = arrangement.defaultViewProperties
        playerProperties.width.preferred = .fractional(0.45)
        arrangement.setViewProperties(playerProperties, for: .primary)
        arrangementController.updateArrangement(arrangement)
        addChild(arrangementController)
        arrangementController.view.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(arrangementController.view, aboveSubview: layout.background)
        arrangementController.view.anchorToAllSidesOf(view: view)
        arrangementController.didMove(toParent: self)

        // From here on, the header and the pages move between the panes.
        if let headerStackView = headerView.superview, headerStackView !== view {
            headerView.removeFromSuperview()
            headerStackView.removeFromSuperview()
        }
        mainScrollView.removeFromSuperview()
        closeBtn.removeFromSuperview()
        tabsView.fadesEdgesWithMask = true

        layout.grabber.accessibilityLabel = closeBtn.accessibilityLabel
        layout.grabber.accessibilityIdentifier = closeBtn.accessibilityIdentifier
        layout.grabber.onTap = { [weak self] in
            self?.closeNowPlaying()
        }
        layout.divider.translatesAutoresizingMaskIntoConstraints = false
        layout.divider.isUserInteractionEnabled = false

        addCustomObserver(.episodeEmbeddedArtworkLoaded, selector: #selector(largeScreenArtworkDidLoad))
        addCustomObserver(Constants.Notifications.episodeTranscriptAvailabilityChanged, selector: #selector(largeScreenTranscriptAvailabilityDidChange(_:)))

        // Now Playing is a child of the player pane in both layouts.
        nowPlayingItem.willBeAddedToPlayer()
        layout.playerPane.addChild(nowPlayingItem)
        applyLargeScreenLayout(isSplit: false)
        nowPlayingItem.didMove(toParent: layout.playerPane)
    }

    /// Splits Now Playing and the tabs when the arrangement shows both views, and pages them otherwise.
    func updateLargeScreenLayoutIfNeeded() {
        guard let layout = largeScreenLayout, let windowScene = view.window?.windowScene else { return }

        // `MainTabBarController` forces a compact size class on iPad, and the player inherits it
        // from its presenter, so pass the scene's own size class to the arrangement.
        let horizontalSizeClass = windowScene.traitCollection.horizontalSizeClass
        if layout.horizontalSizeClass != horizontalSizeClass {
            layout.horizontalSizeClass = horizontalSizeClass
            layout.arrangementController.traitOverrides.horizontalSizeClass = horizontalSizeClass
        }

        layout.arrangementController.view.layoutIfNeeded()
        // The state can say the secondary view isn't hidden before the arrangement ever showed it
        // (seen on a folded iPhone Duo), so also check that the tabs pane is on screen.
        let tabsPaneView = layout.tabsPane.view
        let isSplit = layout.arrangementController.state(for: .secondary)?.isHidden == false
            && tabsPaneView?.window != nil
            && tabsPaneView?.bounds.isEmpty == false
        if isSplit != layout.isSplit {
            applyLargeScreenLayout(isSplit: isSplit)
        }
    }

    private func applyLargeScreenLayout(isSplit: Bool) {
        guard let layout = largeScreenLayout,
              let playerPaneView = layout.playerPane.view,
              let nowPlayingView = nowPlayingItem.view else { return }

        layout.isSplit = isSplit

        // The transcript is a tab next to Now Playing rather than covering it.
        if isSplit, nowPlayingItem.displayTranscript {
            nowPlayingItem.displayTranscript = false
        }

        NSLayoutConstraint.deactivate(layout.constraints)
        // The tab pages leave before their scroll view can move to the other pane.
        removeLargeScreenTabPages()
        for movingView: UIView in [headerView, mainScrollView, transcriptContainerView, closeBtn, layout.grabber, layout.divider, nowPlayingView] {
            movingView.removeFromSuperview()
        }

        let tabsHostView: UIView = isSplit ? layout.tabsPane.view : playerPaneView
        tabsHostView.addSubview(headerView)
        tabsHostView.addSubview(mainScrollView)

        var constraints = [
            headerView.topAnchor.constraint(equalTo: tabsHostView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: tabsHostView.safeAreaLayoutGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: tabsHostView.safeAreaLayoutGuide.trailingAnchor),
            mainScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: tabsHostView.leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: tabsHostView.trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: tabsHostView.bottomAnchor)
        ]

        let playerSafeArea = playerPaneView.safeAreaLayoutGuide
        if isSplit {
            playerPaneView.addSubview(nowPlayingView)
            playerPaneView.addSubview(layout.grabber)
            tabsHostView.addSubview(layout.divider)
            constraints += [
                // Line Now Playing up with the pages under the header on the other side.
                nowPlayingView.topAnchor.constraint(equalTo: playerSafeArea.topAnchor, constant: Self.largeScreenHeaderHeight),
                nowPlayingView.leadingAnchor.constraint(equalTo: playerPaneView.leadingAnchor),
                nowPlayingView.trailingAnchor.constraint(equalTo: playerPaneView.trailingAnchor),
                nowPlayingView.bottomAnchor.constraint(equalTo: playerPaneView.bottomAnchor),
                layout.grabber.centerXAnchor.constraint(equalTo: playerSafeArea.centerXAnchor),
                layout.grabber.centerYAnchor.constraint(equalTo: playerSafeArea.topAnchor, constant: Self.largeScreenHeaderHeight / 2),
                layout.divider.topAnchor.constraint(equalTo: tabsHostView.topAnchor),
                layout.divider.bottomAnchor.constraint(equalTo: tabsHostView.bottomAnchor),
                layout.divider.leadingAnchor.constraint(equalTo: tabsHostView.leadingAnchor),
                layout.divider.widthAnchor.constraint(equalToConstant: 1),
                tabsView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16)
            ]
        } else {
            headerView.addSubview(closeBtn)
            addNowPlayingPage()
            constraints += [
                closeBtn.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 14),
                closeBtn.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
                tabsView.leadingAnchor.constraint(equalTo: closeBtn.trailingAnchor, constant: 4)
            ]
        }

        // The transcript covers Now Playing down to its playback controls, like it does on iPhone.
        playerPaneView.addSubview(transcriptContainerView)
        constraints += [
            isSplit
                ? transcriptContainerView.topAnchor.constraint(equalTo: playerSafeArea.topAnchor, constant: 8)
                : transcriptContainerView.topAnchor.constraint(equalTo: tabsView.topAnchor),
            transcriptContainerView.leadingAnchor.constraint(equalTo: playerSafeArea.leadingAnchor),
            transcriptContainerView.trailingAnchor.constraint(equalTo: playerSafeArea.trailingAnchor),
            transcriptContainerView.bottomAnchor.constraint(equalTo: nowPlayingItem.bottomControlsStackView.topAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
        layout.constraints = constraints

        mainScrollView.isScrollEnabled = isSplit || !nowPlayingItem.displayTranscript
        updateLargeScreenTabs(force: true)
    }

    /// Lays out the tab pages after Now Playing (when it's paged with them) for the tabs the
    /// current episode has. Rebuilds them only when the tabs change unless `force` is set.
    func updateLargeScreenTabs(force: Bool) {
        guard let layout = largeScreenLayout, let playingEpisode = PlaybackManager.shared.currentEpisode else { return }

        tabsView.themeDidChange()

        let shouldShowTranscript = layout.isSplit && isLargeScreenTranscriptAvailable(for: playingEpisode)
        let shouldShowNotes = (playingEpisode is Episode)
        let shouldShowChapters = PlaybackManager.shared.chapterCount() > 0
        if !force, shouldShowTranscript == layout.showingTranscript, shouldShowNotes == showingNotes, shouldShowChapters == showingChapters, showingBookmarks {
            return
        }

        mainScrollView.setContentOffset(.zero, animated: false)
        tabsView.currentTab = 0
        removeLargeScreenTabPages()

        layout.showingTranscript = shouldShowTranscript
        showingNotes = shouldShowNotes
        showingChapters = shouldShowChapters
        showingBookmarks = true

        var tabs: [(PlayerTabs, PlayerItemViewController)] = []
        if shouldShowTranscript {
            tabs.append((.transcript, largeScreenTranscriptTab(in: layout)))
        }
        if shouldShowNotes {
            tabs.append((.showNotes, showNotesItem))
        }
        if shouldShowChapters {
            tabs.append((.chapters, chaptersItem))
        }
        tabs.append((.bookmarks, bookmarksItem))

        tabsView.tabs = (layout.isSplit ? [] : [.nowPlaying]) + tabs.map(\.0)
        // Selecting the first tab scrolls it into view, but the panes have no size until the
        // arrangement lays them out in a window, so start the tabs from the first one here.
        tabsView.setContentOffset(.zero, animated: false)

        // The pages are children of the pane they're shown in.
        let host = layout.isSplit ? layout.tabsPane : layout.playerPane
        var previousPage: UIView? = layout.isSplit ? nil : nowPlayingItem.view
        finalScrollViewConstraint?.isActive = false
        for (_, item) in tabs {
            guard let page = item.view else { continue }

            item.usesLargeScreenStyle = true
            item.willBeAddedToPlayer()
            host.addChild(item)
            mainScrollView.addSubview(page)
            NSLayoutConstraint.activate([
                page.leadingAnchor.constraint(equalTo: previousPage?.trailingAnchor ?? mainScrollView.leadingAnchor),
                page.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
                page.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
                page.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
                page.heightAnchor.constraint(equalTo: mainScrollView.heightAnchor)
            ])
            item.didMove(toParent: host)
            previousPage = page
        }

        if let previousPage {
            let finalConstraint = previousPage.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor)
            finalConstraint.isActive = true
            finalScrollViewConstraint = finalConstraint
        }
    }

    private func removeLargeScreenTabPages() {
        let items: [PlayerItemViewController] = [showNotesItem, chaptersItem, bookmarksItem]
        for item in items where item.parent != nil {
            item.willMove(toParent: nil)
            item.view.removeFromSuperview()
            item.removeFromParent()
        }

        if let transcriptTab = largeScreenLayout?.transcriptTab, transcriptTab.parent != nil {
            removeLargeScreenTranscriptPaywall()
            transcriptTab.willBeRemovedFromPlayer()
            transcriptTab.willMove(toParent: nil)
            transcriptTab.view.removeFromSuperview()
            transcriptTab.removeFromParent()
        }
    }

    // MARK: - Transcript

    private func largeScreenTranscriptTab(in layout: PlayerLargeScreenLayout) -> TranscriptViewController {
        if let transcriptTab = layout.transcriptTab {
            return transcriptTab
        }

        let transcriptTab = TranscriptViewController(playbackManager: PlaybackManager.shared)
        transcriptTab.usesLargeScreenStyle = true
        transcriptTab.isPlayerTab = true
        transcriptTab.scrollViewHandler = self
        transcriptTab.containerDelegate = self
        transcriptTab.view.translatesAutoresizingMaskIntoConstraints = false
        transcriptTab.showGeneratedTranscriptsPremiumOverlay = { [weak self] in
            self?.showLargeScreenTranscriptPaywall()
        }
        layout.transcriptTab = transcriptTab
        return transcriptTab
    }

    /// Whether the episode has a transcript. Until `Episode.checkTranscriptAvailability()`
    /// reports back for a new episode, it doesn't.
    private func isLargeScreenTranscriptAvailable(for episode: BaseEpisode) -> Bool {
        guard let layout = largeScreenLayout, let episode = episode as? Episode else { return false }

        if let availability = layout.transcriptAvailability, availability.episodeUuid == episode.uuid {
            return availability.isAvailable
        }
        layout.transcriptAvailability = (episode.uuid, false)
        episode.checkTranscriptAvailability()
        return false
    }

    @objc private func largeScreenTranscriptAvailabilityDidChange(_ notification: Notification) {
        guard let layout = largeScreenLayout,
              let episodeUuid = notification.userInfo?["episodeUuid"] as? String,
              let isAvailable = notification.userInfo?["isAvailable"] as? Bool,
              episodeUuid == PlaybackManager.shared.currentEpisode?.uuid else { return }

        layout.transcriptAvailability = (episodeUuid, isAvailable)
        updateLargeScreenTabs(force: false)
    }

    /// Covers the transcript tab, not the whole player, with the Plus paywall for generated
    /// transcripts. Closing it moves on to the next tab rather than revealing the transcript.
    private func showLargeScreenTranscriptPaywall() {
        guard let layout = largeScreenLayout, layout.transcriptPaywall == nil,
              let transcriptTab = layout.transcriptTab, let transcriptView = transcriptTab.view else { return }

        let paywall = GeneratedTranscriptsPremiumOverlay(playbackManager: PlaybackManager.shared)
        paywall.view.translatesAutoresizingMaskIntoConstraints = false
        paywall.dismissTranscript = { [weak self] in
            guard let self, let index = self.tabsView.tabs.firstIndex(of: .transcript), index + 1 < self.tabsView.tabs.count else { return }
            self.didSwitchToTab(index: index + 1)
        }
        paywall.purchaseSuccessfull = { [weak self] in
            self?.removeLargeScreenTranscriptPaywall()
        }

        transcriptTab.addChild(paywall)
        transcriptView.addSubview(paywall.view)
        paywall.view.anchorToAllSidesOf(view: transcriptView)
        paywall.didMove(toParent: transcriptTab)
        paywall.didAppear()
        layout.transcriptPaywall = paywall
    }

    private func removeLargeScreenTranscriptPaywall() {
        guard let layout = largeScreenLayout, let paywall = layout.transcriptPaywall else { return }

        paywall.didDisappear()
        paywall.willMove(toParent: nil)
        paywall.view.removeFromSuperview()
        paywall.removeFromParent()
        layout.transcriptPaywall = nil
    }

    /// Stops the transcript tab (its display link keeps it alive otherwise) once the player is gone.
    func largeScreenViewDidDisappear() {
        guard isBeingDismissed, let transcriptTab = largeScreenLayout?.transcriptTab, transcriptTab.parent != nil else { return }

        if tabsView.tabs[safe: tabsView.currentTab] == .transcript {
            transcriptTab.didDisappear()
        }
        removeLargeScreenTranscriptPaywall()
        transcriptTab.willBeRemovedFromPlayer()
    }

    /// Makes Now Playing the first page, ending the content until the tabs are added after it.
    private func addNowPlayingPage() {
        guard let nowPlayingView = nowPlayingItem.view else { return }

        mainScrollView.addSubview(nowPlayingView)
        finalScrollViewConstraint?.isActive = false
        let finalConstraint = nowPlayingView.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor)
        NSLayoutConstraint.activate([
            nowPlayingView.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor),
            nowPlayingView.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
            nowPlayingView.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
            nowPlayingView.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
            nowPlayingView.heightAnchor.constraint(equalTo: mainScrollView.heightAnchor),
            finalConstraint
        ])
        finalScrollViewConstraint = finalConstraint
    }

    func updateLargeScreenColors() {
        guard let layout = largeScreenLayout else { return }

        layout.background.update(episode: PlaybackManager.shared.currentEpisode, tintColor: PlayerColorHelper.playerBackgroundColor01())
        layout.grabber.updateColors()
        layout.divider.backgroundColor = ThemeColor.playerContrast05()
    }

    @objc private func largeScreenArtworkDidLoad() {
        largeScreenLayout?.background.reloadArtwork(for: PlaybackManager.shared.currentEpisode)
    }

    /// The height of the header with the tabs, below the top safe area.
    private static var largeScreenHeaderHeight: CGFloat {
        50
    }
}

/// An empty pane of the large screen player arrangement; the player lays out its content.
final class PlayerArrangementPaneViewController: UIViewController {
    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
    }
}

/// The handle above Now Playing when the tabs are next to it. Tapping it closes the player. It's
/// not a `UIControl`, so the player's dismiss pan can still start on it.
final class PlayerGrabberView: UIView {
    var onTap: (() -> Void)?

    private let handle = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.isUserInteractionEnabled = false
        handle.layer.cornerRadius = 2.5
        addSubview(handle)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 88),
            heightAnchor.constraint(equalToConstant: 44),
            handle.centerXAnchor.constraint(equalTo: centerXAnchor),
            handle.centerYAnchor.constraint(equalTo: centerYAnchor),
            handle.widthAnchor.constraint(equalToConstant: 36),
            handle.heightAnchor.constraint(equalToConstant: 5)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateColors() {
        handle.backgroundColor = ThemeColor.playerContrast03()
    }

    override func accessibilityActivate() -> Bool {
        onTap?()
        return true
    }

    @objc private func handleTap() {
        onTap?()
    }
}
