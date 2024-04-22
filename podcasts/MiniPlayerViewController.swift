import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class MiniPlayerViewController: SimpleNotificationsViewController {
    enum PlayerOpenState {
        case closed, beingDragged, open, animating
    }

    var playerOpenState = PlayerOpenState.closed

    @IBOutlet var playPauseBtn: PlayPauseButton!
    @IBOutlet var skipBackBtn: UIButton!
    @IBOutlet var skipFwdBtn: UIButton!

    @IBOutlet var upNextBtn: UpNextButton!

    @IBOutlet var playbackProgressView: ProgressLine!

    @IBOutlet var podcastArtwork: PodcastImageView!
    @IBOutlet var mainView: MiniPlayerBackingView!
    @IBOutlet var shadowView: UIView!

    private var lastEpisodeUuidImageLoaded = ""
    private var lastEpisodeUuidAutoOpened = ""
    var fullScreenPlayer: PlayerContainerViewController?

    var panUpRecognizer: UIPanGestureRecognizer!
    var longPressRecognizer: UILongPressGestureRecognizer!

    var heightConstraint: NSLayoutConstraint?

    var upNextViewController: UpNextViewController?

    private let analyticsPlaybackHelper = AnalyticsPlaybackHelper.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        addGestureRecognizers()

        view.isHidden = false

        setupCornersAndShadow()
        addUINotificationObservers()
        playbackStateDidChange()
        themeChanged()
    }

    private func setupCornersAndShadow() {
        let cornerRadius = CGFloat(12)
        mainView.layer.cornerRadius = cornerRadius
        mainView.layer.masksToBounds = true

        shadowView.backgroundColor = .clear
        shadowView.layer.shadowColor = ThemeColor.primaryText01().withAlphaComponent(0.8).cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 0)
        shadowView.layer.shadowRadius = 15
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.cornerRadius = cornerRadius
        shadowView.layer.shadowPath =  UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: cornerRadius).cgPath
        shadowView.layer.shouldRasterize = true
        shadowView.layer.rasterizationScale = UIScreen.main.scale
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shadowView.layer.shadowPath =  UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 12).cgPath
    }

    deinit {
        removeAllCustomObservers()
    }

    @IBAction func playPauseTapped(_ sender: Any) {
        analyticsPlaybackHelper.currentSource = analyticsSource
        HapticsHelper.triggerPlayPauseHaptic()
        PlaybackManager.shared.playPause()
    }

    @IBAction func upNextTapped(_ sender: Any) {
        showUpNext(from: .miniPlayer)
    }

    @IBAction func skipBackTapped(_ sender: Any) {
        analyticsPlaybackHelper.currentSource = analyticsSource
        HapticsHelper.triggerSkipBackHaptic()
        PlaybackManager.shared.skipBack()
    }

    @IBAction func skipForwardTapped(_ sender: Any) {
        analyticsPlaybackHelper.currentSource = analyticsSource
        HapticsHelper.triggerSkipForwardHaptic()
        PlaybackManager.shared.skipForward()
    }

    func desiredHeight() -> CGFloat {
        70
    }

    func aboutToDisplayFullScreenPlayer() {
        guard let rootVC = rootViewController() else { return }

        guard !FeatureFlag.newPlayerTransition.enabled else {
            if fullScreenPlayer == nil {
                fullScreenPlayer = PlayerContainerViewController()
            }

            return
        }

        let viewSize = rootVC.view.bounds.size
        let startingYPos = fullScreenPlayer?.view.frame.minY ?? viewSize.height
        if fullScreenPlayer == nil {
            fullScreenPlayer = PlayerContainerViewController()
            rootVC.addChild(fullScreenPlayer!)
            rootVC.view.addSubview(fullScreenPlayer!.view)
        }

        fullScreenPlayer?.view.frame = CGRect(x: 0, y: startingYPos, width: viewSize.width, height: viewSize.height)

        // prevent swipe to go back while the player is open
        rootNavController()?.interactivePopGestureRecognizer?.isEnabled = false
    }

    func finishedWithFullScreenPlayer() {
        guard let rootVC = rootViewController() else { return }

        guard !FeatureFlag.newPlayerTransition.enabled else {
            rootViewController()?.setNeedsStatusBarAppearanceUpdate()
            rootViewController()?.setNeedsUpdateOfHomeIndicatorAutoHidden()

            fullScreenPlayer?.view.removeFromSuperview()
            fullScreenPlayer = nil

            // update the mini player on full screen player close
            playbackStateDidChange()
            playbackProgressDidChange()
            return
        }

        if fullScreenPlayer?.presentedViewController != nil {
            fullScreenPlayer?.dismiss(animated: false, completion: nil)
        }

        // there's a bug in iOS where because the player is added as a child controller to the tab bar, the tab bar adds it as a tab
        // that would be fine, except if we call fullScreenPlayer.removeFromParent() it removes the controller but not the tab, so here we drop it manually
        // if you ever change this, check that this bug hasn't come back: https://github.com/shiftyjelly/pocketcasts-ios/issues/3338
        if rootVC.children.count == 5 {
            rootVC.viewControllers = rootVC.viewControllers?.dropLast()
        }
        fullScreenPlayer?.removeFromParent() // still call this in case it has other special handling in it

        rootViewController()?.setNeedsStatusBarAppearanceUpdate()
        rootViewController()?.setNeedsUpdateOfHomeIndicatorAutoHidden()
        fullScreenPlayer?.view.removeFromSuperview()
        fullScreenPlayer = nil

        // re-enable the disabled swipe back gesture
        rootNavController()?.interactivePopGestureRecognizer?.isEnabled = true

        // update the mini player on full screen player close
        playbackStateDidChange()
        playbackProgressDidChange()
    }

    func changeHeightTo(_ height: CGFloat) {
        if heightConstraint == nil {
            heightConstraint = view.heightAnchor.constraint(equalToConstant: height)
            heightConstraint?.isActive = true
        } else {
            heightConstraint?.constant = height
        }
    }

    func addUINotificationObservers() {
        addCustomObserver(Constants.Notifications.playbackStarting, selector: #selector(playbackStarting))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(playbackStarted))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(playbackStateDidChange))
        addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(playbackStateDidChange))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(playbackStateDidChange))
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(playbackProgressDidChange))
        addCustomObserver(Constants.Notifications.googleCastStatusChanged, selector: #selector(playbackStateDidChange))
        addCustomObserver(Constants.Notifications.statusBarHeightChanged, selector: #selector(statusBarHeightDidChange))

        addCustomObserver(Constants.Notifications.podcastImageReCacheRequired, selector: #selector(updateRequired))

        addCustomObserver(.episodeEmbeddedArtworkLoaded, selector: #selector(updateRequired))

        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(upNextListChanged))
        addCustomObserver(Constants.Notifications.podcastDeleted, selector: #selector(upNextListChanged))

        addCustomObserver(UIApplication.didBecomeActiveNotification, selector: #selector(playbackStateDidChange))

        addCustomObserver(Constants.Notifications.themeChanged, selector: #selector(themeChanged))
        addCustomObserver(Constants.Notifications.currentlyPlayingEpisodeUpdated, selector: #selector(updateRequired))
    }

    func rootViewController() -> MainTabBarController? {
        if let controller = view.window?.rootViewController as? MainTabBarController {
            return controller
        }

        return nil
    }

    private func rootNavController() -> UINavigationController? {
        if let rootNav = rootViewController()?.selectedViewController as? UINavigationController {
            return rootNav
        }

        return nil
    }

    func miniPlayerShowing() -> Bool {
        !view.isHidden
    }

    private func setupForEpisode(_ episode: BaseEpisode) {
        updateColors()

        if lastEpisodeUuidImageLoaded != episode.uuid {
            lastEpisodeUuidImageLoaded = episode.uuid
            podcastArtwork.setBaseEpisode(episode: episode, size: .list)
        }
    }

    @objc private func playbackStarted() {
        if let episode = PlaybackManager.shared.currentEpisode() {
            setupForEpisode(episode)
            showMiniPlayer()
            let shouldOpenAutomatically: Bool
            shouldOpenAutomatically = Settings.openPlayerAutomatically
            if shouldOpenAutomatically || episode.videoPodcast(), lastEpisodeUuidAutoOpened != episode.uuid {
                lastEpisodeUuidAutoOpened = episode.uuid

                // we called show mini player above, which might have spent time animating itself into view, so give that time to finish
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Animation.defaultAnimationTime) {
                    self.openFullScreenPlayer()
                }
            }
        } else {
            hideMiniPlayer(true)
        }
    }

    @objc private func playbackStarting() {
        playbackStateDidChange()
    }

    @objc private func statusBarHeightDidChange() {
        if miniPlayerShowing() {
            hideMiniPlayer(false)
            showMiniPlayer()
        }
    }

    @objc private func upNextListChanged() {
        playbackStateDidChange()
    }

    @objc private func playbackStateDidChange() {
        guard let episodePlaying = PlaybackManager.shared.currentEpisode() else {
            hideMiniPlayer(true)

            return
        }

        setupForEpisode(episodePlaying)
        showMiniPlayer()
        playbackProgressDidChange()
    }

    @objc private func themeChanged() {
        updateColors()
    }

    @objc private func playbackProgressDidChange() {
        if playerOpenState == .open { return } // don't update the mini player while the full screen player is open

        let currentTime = PlaybackManager.shared.currentTime()
        let duration = PlaybackManager.shared.duration()

        var progress: CGFloat = 0
        if currentTime > 0, duration > 0 {
            progress = min(1, CGFloat(currentTime / duration))
        }

        playbackProgressView.progress = progress
        playbackProgressView.indeterminant = PlaybackManager.shared.buffering()

        let amountBuferred = PlaybackManager.shared.futureBufferAvailable()
        if amountBuferred > 0 {
            playbackProgressView.buferredAmount = CGFloat(amountBuferred / (duration - currentTime))
        }
    }

    private func updateColors() {
        let actionColor: UIColor
        if let podcast = podcastForEpisode(PlaybackManager.shared.currentEpisode()) {
            actionColor = Theme.isDarkTheme() ? ColorManager.darkThemeTintForPodcast(podcast) : ColorManager.lightThemeTintForPodcast(podcast)
        } else {
            if let episode = PlaybackManager.shared.currentEpisode() as? UserEpisode, episode.imageColor > 0 {
                actionColor = AppTheme.userEpisodeColor(number: Int(episode.imageColor))
            } else {
                actionColor = AppTheme.userEpisodeColor(number: 1)
            }
        }

        let bgColor = ThemeColor.podcastUi02(podcastColor: actionColor)
        mainView.backgroundColor = bgColor
        shadowView.layer.shadowColor = ThemeColor.primaryText01().withAlphaComponent(0.3).cgColor
        playPauseBtn.playButtonColor = bgColor

        playbackProgressView.updateColors()

        let iconColor = ThemeColor.podcastIcon03(podcastColor: actionColor)
        playPauseBtn.circleColor = iconColor

        skipBackBtn.tintColor = iconColor
        skipFwdBtn.tintColor = iconColor
        upNextBtn.iconColor = iconColor

        playPauseBtn.isPlaying = PlaybackManager.shared.playing()
    }

    private func podcastForEpisode(_ episode: BaseEpisode?) -> Podcast? {
        if let episode = PlaybackManager.shared.currentEpisode() as? Episode {
            return episode.parentPodcast()
        }

        return nil
    }

    @objc private func updateRequired() {
        guard let episode = PlaybackManager.shared.currentEpisode() else { return }

        updateColors()

        if let userEpisode = episode as? UserEpisode {
            podcastArtwork.setUserEpisode(uuid: userEpisode.uuid, size: .list)
        } else {
            podcastArtwork.setBaseEpisode(episode: episode, size: .list)
        }
    }

    func showUpNext(from source: UpNextViewSource) {
        upNextViewController = UpNextViewController(source: source)
        guard let upNextController = upNextViewController else { return }

        let navWrapper = SJUIUtils.navController(for: upNextController, iconStyle: .secondaryText01, themeOverride: upNextController.themeOverride)
        navWrapper.modalPresentationStyle = .formSheet
        rootViewController()?.present(navWrapper, animated: true, completion: nil)
    }
}

extension MiniPlayerViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .miniplayer
    }
}
