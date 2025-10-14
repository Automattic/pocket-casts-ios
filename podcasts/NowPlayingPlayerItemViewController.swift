#if !APPCLIP
import Agrume
#endif
import AVKit
import SafariServices
import UIKit
import PocketCastsUtils
import SwiftUI
import PocketCastsServer

class NowPlayingPlayerItemViewController: PlayerItemViewController {
    var showingCustomImage = false
    var lastChapterIndexRendered = -1

    private var bannerTask: Task<Void, Never>? = nil

    // Detect Display Zoom (zoomed display makes UI elements appear larger).
    // Scale controls down slightly when zoomed to avoid oversized buttons.
    private var isZoomed: Bool {
        A11y.isDisplayZoomed
    }

    var videoViewController: VideoViewController?

    @IBOutlet var skipBackBtn: SkipButton! {
        didSet {
            skipBackBtn.skipBack = true
        }
    }

    @IBOutlet var skipFwdBtn: SkipButton! {
        didSet {
            skipFwdBtn.skipBack = false
            skipFwdBtn.longPressed = { [weak self] in
                self?.skipForwardLongPressed()
            }
        }
    }

    @IBOutlet var playPauseBtn: PlayPauseButton!

    @IBOutlet var episodeImage: UIImageView! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.numberOfTouchesRequired = 1
            episodeImage.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var episodeName: ThemeableLabel! {
        didSet {
#if APPCLIP
            episodeName.text = ""
#endif
            episodeName.style = .playerContrast01
        }
    }

    @IBOutlet var podcastName: ThemeableLabel! {
        didSet {
#if APPCLIP
            podcastName.text = ""
#endif
            podcastName.style = .playerContrast02
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(podcastNameTapped))
            podcastName.addGestureRecognizer(tapGesture)

            podcastName.accessibilityTraits = .button
            podcastName.accessibilityHint = L10n.accessibilityHintPlayerNavigateToPodcastLabel
        }
    }

    @IBOutlet var chapterName: ThemeableLabel! {
        didSet {
#if APPCLIP
            chapterName.text = ""
#endif
            chapterName.style = .playerContrast01

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(chapterNameTapped))
            chapterName.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var floatingVideoView: FloatingVideoView! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.numberOfTouchesRequired = 1
            floatingVideoView.addGestureRecognizer(tapGesture)
        }
    }

    // MARK: - Chapters

    @IBOutlet var chapterSkipBackBtn: UIButton! {
        didSet {
            chapterSkipBackBtn.tintColor = ThemeColor.playerContrast01()
        }
    }

    @IBOutlet var chapterSkipFwdBtn: UIButton! {
        didSet {
            chapterSkipFwdBtn.tintColor = ThemeColor.playerContrast01()
        }
    }

    @IBOutlet var chapterCounter: ThemeableLabel! {
        didSet {
            chapterCounter.style = .playerContrast02
        }
    }

    @IBOutlet var chapterTimeLeftLabel: UILabel! {
        didSet {
            chapterTimeLeftLabel.font = chapterTimeLeftLabel.font.monospaced()
        }
    }

    @IBOutlet var chapterProgress: ProgressCircleView! {
        didSet {
            chapterProgress.lineWidth = 2
            chapterProgress.lineColor = ThemeColor.playerContrast03()
        }
    }

    @IBOutlet var chapterLink: UIView! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(chapterLinkTapped))
            chapterLink.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var chapterInfoView: UIView!
    @IBOutlet var episodeInfoView: UIView!

    @IBOutlet var shelfBg: ThemeableView! {
        didSet {
            shelfBg.style = .playerContrast06
        }
    }

    // MARK: - Time Slider

    @IBOutlet var timeSlider: TimeSlider! {
        didSet {
            timeSlider.accessibilityLabel = L10n.accessibilityEpisodePlayback
            timeSlider.delegate = self
        }
    }

    @IBOutlet var playerControlsStackView: UIStackView!

    @IBOutlet var timeSliderHolderView: UIView!

    @IBOutlet var timeElapsed: ThemeableLabel! {
        didSet {
            timeElapsed.style = .playerContrast02
            timeElapsed.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: UIFont.Weight.medium)
        }
    }

    @IBOutlet var timeRemaining: ThemeableLabel! {
        didSet {
            timeRemaining.style = .playerContrast02
            timeRemaining.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: UIFont.Weight.medium)
        }
    }

    @IBOutlet var playPauseHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var fillView: UIView!

    @IBOutlet weak var bottomControlsStackView: UIStackView!

    #if !APPCLIP
    let chromecastBtn = PCAlwaysVisibleCastBtn()
    #endif
    let routePicker = PCRoutePickerView(frame: CGRect.zero)

    #if !APPCLIP
    private lazy var upNextController = UpNextViewController(source: .nowPlaying)
    #endif

    #if !APPCLIP
    lazy var upNextViewController: UIViewController = {
        let controller = SJUIUtils.navController(for: upNextController, iconStyle: .secondaryText01, themeOverride: upNextController.themeOverride)
        controller.modalPresentationStyle = .pageSheet

        return controller
    }()
    #endif

    var lastShelfLoadState = ShelfLoadState()

    private var bannerAdHostingController: PCHostingController<AnyView>?
    private var bannerAdHeightConstraint: NSLayoutConstraint?

    private let analyticsPlaybackHelper = AnalyticsPlaybackHelper.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        #if !APPCLIP
        let upNextPan = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
        upNextPan.delegate = self
        view.addGestureRecognizer(upNextPan)

        chromecastBtn.inactiveTintColor = ThemeColor.playerContrast02()
        chromecastBtn.addTarget(self, action: #selector(googleCastTapped), for: .touchUpInside)
        chromecastBtn.isPointerInteractionEnabled = true

        routePicker.delegate = self
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if !APPCLIP
        // Show the overflow menu
        if AnnouncementFlow.current == .bookmarksPlayer {
            overflowTapped()
        }
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBannerAd()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        bannerTask?.cancel()
    }

    private var lastBoundsAdjustedFor = CGRect.zero

    var analyticsSource: AnalyticsSource {
        .player
    }

    var displayTranscript = false {
        didSet {
#if !APPCLIP
            toggleTranscript()
#endif
        }
    }

    private func loadBannerAd() {
#if !APPCLIP
        if SubscriptionHelper.shouldDisplayPlayerBannerAd {
            DiscoverServerHandler.shared.blazePromotion(for: .player) { [weak self] promotion, shouldAnimate in
                guard let self = self else { return }

                if shouldAnimate {
                    self.bannerTask = Task { [weak self] in
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run {
                            self?.addAdBanner(promotion: promotion, animated: true)
                        }
                    }
                } else {
                    self.addAdBanner(promotion: promotion, animated: false)
                }
            }
        }
#endif
    }

    private var playerContainer: PlayerContainerViewController? {
        parent as? PlayerContainerViewController
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // there's some expensive operations in resizeControls,
        // so only do them if the bounds has actually changed
        if lastBoundsAdjustedFor == view.bounds { return }
        lastBoundsAdjustedFor = view.bounds

        resizeControls()

        #if !APPCLIP
        if FeatureFlag.bannerAdPlayer.enabled {
            updateBannerAdHeight()
        }
        #endif
    }

    private func resizeControls() {
        let spacing: CGFloat
        if view.bounds.width <= 320 {
            spacing = 8
        } else if view.bounds.width <= 375 {
            spacing = 20
        } else {
            spacing = 30
        }

        if playerControlsStackView.spacing != spacing { playerControlsStackView.spacing = spacing }

        // Base height for play/pause. If zoomed and not showing transcript, scale down a bit.
        let baseHeight: CGFloat = displayTranscript ? 40 : (view.bounds.height > 710 ? 100 : 80)
        let scaledHeight: CGFloat = (!displayTranscript && isZoomed) ? baseHeight * 0.9 : baseHeight
        if playPauseHeightConstraint.constant != scaledHeight { playPauseHeightConstraint.constant = scaledHeight }

        // Ensure skip buttons are not too large on zoomed displays.
        // Use small size either when showing transcript or when display is zoomed.
        let skipSize: SkipButton.Size = (displayTranscript || isZoomed) ? .small : .large
        skipBackBtn.changeSize(to: skipSize)
        skipFwdBtn.changeSize(to: skipSize)

        view.layoutIfNeeded()
    }

    override func willBeAddedToPlayer() {
        update()
        addObservers()
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()

        #if !APPCLIP
        if FeatureFlag.bannerAdPlayer.enabled {
            removeBannerAd()
        }
        #endif
    }

    override func themeDidChange() {
        lastShelfLoadState = ShelfLoadState()
        update()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        #if !APPCLIP
        if FeatureFlag.bannerAdPlayer.enabled {
            // Update banner height when text size category changes
            if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
                updateBannerAdHeight()
            }
        }
        #endif
    }

    // MARK: - Interface Actions

    @IBAction func skipBackTapped(_ sender: Any) {
        analyticsPlaybackHelper.currentSource = analyticsSource
        HapticsHelper.triggerSkipBackHaptic()
        PlaybackManager.shared.skipBack()
    }

    @IBAction func playPauseTapped(_ sender: Any) {
        analyticsPlaybackHelper.currentSource = analyticsSource
        HapticsHelper.triggerPlayPauseHaptic()
        PlaybackManager.shared.playPause()
    }

    @IBAction func skipFwdTapped(_ sender: Any) {
        analyticsPlaybackHelper.currentSource = analyticsSource
        HapticsHelper.triggerSkipForwardHaptic()
        PlaybackManager.shared.skipForward()
    }

    @IBAction func chapterSkipBackTapped(_ sender: Any) {
        PlaybackManager.shared.skipToPreviousChapter()
        Analytics.track(.playerPreviousChapterTapped)
    }

    @IBAction func chapterSkipForwardTapped(_ sender: Any) {
        PlaybackManager.shared.skipToNextChapter()
        Analytics.track(.playerNextChapterTapped)
    }

    @objc private func chapterLinkTapped() {
        let chapters = PlaybackManager.shared.currentChapters()
        guard let urlString = chapters.url, let url = URL(string: urlString) else { return }

        #if APPCLIP
        //TODO: Prompt to install app
        #else
            if Settings.openLinks {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                present(SFSafariViewController(with: url), animated: true)
            }
        #endif
    }

    @objc private func imageTapped() {
#if !APPCLIP
        guard let artwork = episodeImage.image else { return }

        let agrume = Agrume(image: artwork, background: .blurred(.regular))
        agrume.show(from: self)
#endif
    }

    @objc private func videoTapped() {
        guard let episode = PlaybackManager.shared.currentEpisode() else { return }

        if episode.videoPodcast() {
            let videoController = VideoViewController()
            videoViewController = videoController
            videoViewController?.modalTransitionStyle = .crossDissolve
            videoViewController?.modalPresentationStyle = .fullScreen
            videoViewController?.willAttachPlayer = { [weak self] in
                self?.floatingVideoView.player = nil
            }
            videoViewController?.willDeattachPlayer = { [weak self] in
                self?.floatingVideoView.player = PlaybackManager.shared.internalPlayerForVideoPlayback()
            }

            present(videoController, animated: true, completion: nil)
        }
    }

    @objc private func chapterNameTapped() {
        containerDelegate?.scrollToCurrentChapter()
    }

    @objc private func podcastNameTapped() {
        Analytics.track(.playerPodcastNameTapped)
        containerDelegate?.navigateToPodcast()
    }

    private func skipForwardLongPressed() {
        guard let episode = PlaybackManager.shared.currentEpisode() else { return }

        let options = OptionsPicker(title: nil, themeOverride: .dark)

        let markPlayedOption = OptionAction(label: L10n.markPlayedShort, icon: nil) {
            AnalyticsEpisodeHelper.shared.currentSource = .playerSkipForwardLongPress
            EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        }
        options.addAction(action: markPlayedOption)

        if PlaybackManager.shared.queue.upNextCount() > 0 {
            let skipToNextAction = OptionAction(label: L10n.nextEpisode, icon: nil) {
                let currentlyPlayingEpisode = PlaybackManager.shared.currentEpisode()
                PlaybackManager.shared.removeIfPlayingOrQueued(episode: currentlyPlayingEpisode, fireNotification: true, userInitiated: true)
            }
            options.addAction(action: skipToNextAction)
        }

        options.show(statusBarStyle: preferredStatusBarStyle)
    }

    #if !APPCLIP
    @objc func googleCastTapped() {
        shelfButtonTapped(.chromecast)

        let themeOverride = Theme.sharedTheme.activeTheme.isDark ? Theme.sharedTheme.activeTheme : .dark
        let castController = CastToViewController(themeOverride: themeOverride)
        let navController = SJUIUtils.navController(for: castController, themeOverride: themeOverride)
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true, completion: nil)
    }

    private func toggleTranscript() {
        let isShowing = displayTranscript

        skipBackBtn.prepareForAnimateTransition(withBackground: view.backgroundColor)
        skipFwdBtn.prepareForAnimateTransition(withBackground: view.backgroundColor)
        playPauseBtn.prepareForAnimateTransition()

        playerContainer?.transcriptContainerView.layer.opacity = isShowing ? 0 : 1

        episodeImage.layer.opacity = 1

        if isShowing {
            playerContainer?.showTranscript()
        }

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1, animations: { [weak self] in
            guard let self else { return }

            // Hide/show shelf
            shelfBg.isHidden = isShowing
            shelfBg.layer.opacity = isShowing ? 0 : 1

            // Show/hide transcript container view
            playerContainer?.transcriptContainerView.isHidden = false
            playerContainer?.transcriptContainerView.layer.opacity = isShowing ? 1 : 0

            // Change the stack view that contains the player button
            bottomControlsStackView.distribution = isShowing ? .fill : .equalSpacing
            bottomControlsStackView.spacing = isShowing ? 10 : 30

            // Display/hide the view that will fill the empty space
            fillView.isHidden = !isShowing

            // Change skip back and forward size (also keep small on zoomed displays)
            let skipButtonSize: SkipButton.Size = (isShowing || isZoomed) ? .small : .large
            skipBackBtn.changeSize(to: skipButtonSize)
            skipFwdBtn.changeSize(to: skipButtonSize)
            skipBackBtn.layoutIfNeeded()
            skipFwdBtn.layoutIfNeeded()

            // Ask parent VC to hide/show tabs
            playerContainer?.scrollView(isEnabled: !isShowing)

            resizeControls()
        }, completion: { [weak self] _ in
            guard let self else { return }

            playerContainer?.transcriptContainerView.isHidden = isShowing ? false : true

            if !isShowing {
                playerContainer?.hideTranscript()
            } else {
                episodeImage.layer.opacity = 0
            }

            playPauseBtn.finishedTransition()
            skipBackBtn.finishedTransition()
            skipFwdBtn.finishedTransition()
        })
    }

    // MARK: Banner Ad

    func addAdBanner(promotion: BlazePromotion, animated: Bool = true) {
        removeBannerAd()

        guard let stackView = episodeImage.superview as? UIStackView else { return }

        let model = BannerAdModel(promotion: promotion) {
            UIApplication.shared.openSafariVCIfPossible(promotion.urlApple)
        }

        let adView = BannerAdView(model: model, colors: .playerColors(Theme.sharedTheme)).padding(16)
        let hostingController = PCHostingController(rootView: AnyView(adView))

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        let targetSize = CGSize(width: stackView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = hostingController.sizeThatFits(in: targetSize)

        addChild(hostingController)
        let adUiView = hostingController.view!

        stackView.insertArrangedSubview(adUiView, at: 0)

        adUiView.alpha = 0
        let topConstraint = adUiView.topAnchor.constraint(equalTo: view.topAnchor, constant: -120)

        let heightConstraint = hostingController.view.heightAnchor.constraint(equalToConstant: size.height)
        NSLayoutConstraint.activate([
            heightConstraint,
            topConstraint,
        ])

        hostingController.didMove(toParent: self)
        bannerAdHostingController = hostingController
        bannerAdHeightConstraint = heightConstraint

        view.layoutIfNeeded()

        if animated {
            // Animate move first
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                topConstraint.constant = 0
                self.view.layoutIfNeeded()
            }

            // Animate opacity second so it's more noticeable
            UIView.animate(withDuration: 0.2, delay: 0.05) {
                adUiView.alpha = 1
            }
        } else {
            topConstraint.constant = 0
            adUiView.alpha = 1
        }
    }

    private func removeBannerAd() {
        guard let hostingController = bannerAdHostingController else { return }

        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        bannerAdHostingController = nil
        bannerAdHeightConstraint = nil
    }

    private func updateBannerAdHeight() {
        guard let hostingController = bannerAdHostingController,
              let heightConstraint = bannerAdHeightConstraint,
              let stackView = episodeImage.superview as? UIStackView else { return }

        let targetSize = CGSize(width: stackView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = hostingController.sizeThatFits(in: targetSize)

        heightConstraint.constant = size.height
        view.layoutIfNeeded()
    }

    #endif
}
