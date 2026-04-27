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
    @IBOutlet var mainView: UIView!
    @IBOutlet var shadowView: UIView!

    @IBOutlet var gradientView: MiniPlayerGradientView!

    private var lastEpisodeUuidImageLoaded = ""
    private var lastEpisodeUuidAutoOpened = ""
    var fullScreenPlayer: PlayerContainerViewController?

    var panUpRecognizer: UIPanGestureRecognizer!
    var longPressRecognizer: UILongPressGestureRecognizer!

    var heightConstraint: NSLayoutConstraint?

    var upNextViewController: UpNextViewController?

    private let analyticsPlaybackHelper = AnalyticsPlaybackHelper.shared

    private var glassContainer: UIVisualEffectView?
    private var episodeTitleLabel: UILabel?
    private var episodeTimeLeftLabel: UILabel?


    override func viewDidLoad() {
        super.viewDidLoad()

        addGestureRecognizers()

        view.isHidden = false

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            setupLiquidGlassLayout()
        } else {
            setupCorners()
        }
        addUINotificationObservers()
        playbackStateDidChange()
        themeChanged()
    }

    private func setupCorners() {
        mainView.layer.cornerRadius = MiniPlayerShadowView.Constants.shadowCornerRadius
        mainView.layer.masksToBounds = true
    }

    @available(iOS 26.0, *)
    private func setupLiquidGlassLayout() {
        gradientView.isHidden = true
        shadowView.isHidden = true
        mainView.backgroundColor = .clear
        mainView.layer.cornerRadius = 0
        playbackProgressView.isHidden = true
        upNextBtn.isHidden = true


        let effectView = UIVisualEffectView(effect: {
            let effect = UIGlassEffect(style: .regular)
            effect.isInteractive = true
            return effect
        }())
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.clipsToBounds = true
        effectView.layer.cornerCurve = .continuous
        view.addSubview(effectView)
        glassContainer = effectView

        let contentView = effectView.contentView

        podcastArtwork.removeFromSuperview()
        skipBackBtn.removeFromSuperview()
        playPauseBtn.removeFromSuperview()
        skipFwdBtn.removeFromSuperview()

        podcastArtwork.translatesAutoresizingMaskIntoConstraints = false
        skipBackBtn.translatesAutoresizingMaskIntoConstraints = false
        playPauseBtn.translatesAutoresizingMaskIntoConstraints = false
        skipFwdBtn.translatesAutoresizingMaskIntoConstraints = false

        podcastArtwork.layer.cornerRadius = 6
        podcastArtwork.layer.masksToBounds = true

        playPauseBtn.visualSize = 28

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .font(ofSize: 12, weight: .medium, scalingWith: .subheadline)
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.adjustsFontForContentSizeCategory = true
        episodeTitleLabel = title

        let timeLeft = UILabel()
        timeLeft.translatesAutoresizingMaskIntoConstraints = false
        timeLeft.font = .font(ofSize: 11, weight: .regular, scalingWith: .footnote)
        timeLeft.numberOfLines = 1
        timeLeft.adjustsFontForContentSizeCategory = true
        episodeTimeLeftLabel = timeLeft

        let textStack = UIStackView(arrangedSubviews: [title, timeLeft])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 1

        let buttonStack = UIStackView(arrangedSubviews: [skipBackBtn, playPauseBtn, skipFwdBtn])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center

        contentView.addSubview(podcastArtwork)
        contentView.addSubview(textStack)
        contentView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            effectView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            effectView.heightAnchor.constraint(equalToConstant: 48),

            podcastArtwork.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            podcastArtwork.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            podcastArtwork.widthAnchor.constraint(equalToConstant: 30),
            podcastArtwork.heightAnchor.constraint(equalToConstant: 30),

            textStack.leadingAnchor.constraint(equalTo: podcastArtwork.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: buttonStack.leadingAnchor, constant: 4),

            skipBackBtn.widthAnchor.constraint(equalToConstant: 68),
            playPauseBtn.widthAnchor.constraint(equalToConstant: 68),
            skipFwdBtn.widthAnchor.constraint(equalToConstant: 68),

            buttonStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let glassContainer {
            glassContainer.layer.cornerRadius = glassContainer.bounds.height / 2
        }
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
        guard rootViewController() != nil else { return }

        if fullScreenPlayer == nil {
            fullScreenPlayer = PlayerContainerViewController()
        }
    }

    func finishedWithFullScreenPlayer() {
        guard rootViewController() != nil else { return }

        rootViewController()?.setNeedsStatusBarAppearanceUpdate()
        rootViewController()?.setNeedsUpdateOfHomeIndicatorAutoHidden()

        fullScreenPlayer?.view.removeFromSuperview()
        fullScreenPlayer = nil

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

        if let episodeTitleLabel, episodeTitleLabel.text != episode.title {
            episodeTitleLabel.text = episode.title
        }
    }

    @objc private func playbackStarted() {
        if let episode = PlaybackManager.shared.currentEpisode() {
            setupForEpisode(episode)
            showMiniPlayer()
            let shouldOpenAutomatically: Bool
            if FeatureFlag.newSettingsStorage.enabled {
                shouldOpenAutomatically = SettingsStore.appSettings.openPlayer
            } else {
                shouldOpenAutomatically = UserDefaults.standard.bool(forKey: Constants.UserDefaults.openPlayerAutomatically)
            }
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
        playbackProgressView.indeterminant = PlaybackManager.shared.buffering() && PlaybackManager.shared.playing()

        let amountBuferred = PlaybackManager.shared.futureBufferAvailable()
        if amountBuferred > 0 {
            playbackProgressView.buferredAmount = CGFloat(amountBuferred / (duration - currentTime))
        }

        if let episodeTimeLeftLabel {
            let remaining = max(0, duration - currentTime)
            let newText: String?
            if remaining > 0 {
                let formatted = TimeFormatter.shared.multipleUnitFormattedShortTime(time: remaining)
                newText = L10n.podcastTimeLeft(formatted)
            } else {
                newText = nil
            }
            if episodeTimeLeftLabel.text != newText {
                episodeTimeLeftLabel.text = newText
            }
        }
    }

    private func updateColors() {
        view.backgroundColor = .clear
        playPauseBtn.isPlaying = PlaybackManager.shared.playing()

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            updateColorsLiquidGlass()
        } else {
            updateColorsLegacy()
        }
    }

    private func updateColorsLegacy() {
        gradientView.colors = [ThemeColor.primaryUi02().withAlphaComponent(0), ThemeColor.primaryUi02()]

        let actionColor: UIColor
        if let podcast = podcastForEpisode(PlaybackManager.shared.currentEpisode()) {
            actionColor = Theme.isDarkTheme() ? ColorManager.darkThemeTintForPodcast(podcast) : ColorManager.lightThemeTintForPodcast(podcast)
        } else if let episode = PlaybackManager.shared.currentEpisode() as? UserEpisode, episode.imageColor > 0 {
            actionColor = AppTheme.userEpisodeColor(number: Int(episode.imageColor))
        } else {
            actionColor = AppTheme.userEpisodeColor(number: 1)
        }
        let bgColor = ThemeColor.podcastUi02(podcastColor: actionColor)
        let iconColor = ThemeColor.podcastIcon03(podcastColor: actionColor)

        mainView.backgroundColor = bgColor

        playPauseBtn.playButtonColor = bgColor
        playPauseBtn.circleColor = iconColor

        playbackProgressView.updateColors()

        skipBackBtn.tintColor = iconColor
        skipFwdBtn.tintColor = iconColor
        upNextBtn.iconColor = iconColor
    }

    @available(iOS 26.0, *)
    private func updateColorsLiquidGlass() {
        let bgColor = ThemeColor.primaryUi02()
        let iconColor = ThemeColor.primaryText01()

        episodeTitleLabel?.textColor = ThemeColor.primaryText01()
        episodeTimeLeftLabel?.textColor = ThemeColor.primaryText01()

        playPauseBtn.playButtonColor = bgColor
        playPauseBtn.circleColor = iconColor

        skipBackBtn.tintColor = iconColor
        skipFwdBtn.tintColor = iconColor
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
