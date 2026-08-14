#if !APPCLIP
import Agrume
#endif
import AVKit
import SafariServices
import UIKit
import PocketCastsUtils
import SwiftUI
import PocketCastsServer

@MainActor
class NowPlayingPlayerItemViewController: PlayerItemViewController {
    var showingCustomImage = false
    var lastChapterIndexRendered = -1

    /// Low-res artwork handed over from the mini player when opening the full
    /// screen player.
    var placeholderArtwork: UIImage?

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

    private(set) var artworkImageView: UIImageView!

    @IBOutlet var episodeName: ThemeableLabel! {
        didSet {
#if APPCLIP
            episodeName.text = ""
#endif
            episodeName.style = .playerContrast01
            episodeName.adjustsFontForContentSizeCategory = true
            episodeName.font = .font(ofSize: 18, weight: .semibold, scalingWith: .largeTitle)
        }
    }

    @IBOutlet var podcastName: ThemeableLabel! {
        didSet {
#if APPCLIP
            podcastName.text = ""
#endif
            podcastName.style = .playerContrast02
            podcastName.adjustsFontForContentSizeCategory = true
            podcastName.font = .font(ofSize: 14, weight: .medium, scalingWith: .largeTitle)

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
            chapterName.adjustsFontForContentSizeCategory = true
            chapterName.font = .font(ofSize: 18, weight: .semibold, scalingWith: .largeTitle)

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
            chapterCounter.adjustsFontForContentSizeCategory = true
            chapterCounter.font = .font(ofSize: 12, weight: .semibold, scalingWith: .largeTitle)
        }
    }

    @IBOutlet var chapterTimeLeftLabel: UILabel! {
        didSet {
            chapterTimeLeftLabel.adjustsFontForContentSizeCategory = true
            chapterTimeLeftLabel.font = .font(ofSize: 11, weight: .semibold, scalingWith: .largeTitle).monospaced()
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
            let baseFont = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: UIFont.Weight.medium)
            let metrics = UIFontMetrics(forTextStyle: .largeTitle)
            timeElapsed.font = metrics.scaledFont(for: baseFont)
            timeElapsed.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var timeRemaining: ThemeableLabel! {
        didSet {
            timeRemaining.style = .playerContrast02
            let baseFont = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: UIFont.Weight.medium)
            let metrics = UIFontMetrics(forTextStyle: .largeTitle)
            timeRemaining.font = metrics.scaledFont(for: baseFont)
            timeRemaining.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var playPauseHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var fillView: UIView!

    @IBOutlet weak var bottomControlsStackView: UIStackView!

    @IBOutlet weak var errorContainer: ThemeableView! {
        didSet {
            errorContainer.style = .playerContrast06
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(errorTapped))
            errorContainer.addGestureRecognizer(tapRecognizer)
        }
    }

    @IBOutlet weak var errorLabel: ThemeableLabel! {
        didSet {
            errorLabel.font = .font(ofSize: 14, weight: .medium, scalingWith: .subheadline)
            errorLabel.style = .playerContrast02
        }
    }

    @IBOutlet weak var playerBottomSpacing: NSLayoutConstraint!

    @IBOutlet weak var errorBottomSpacing: NSLayoutConstraint!

    var errorAutoDismissWork: DispatchWorkItem?

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

    /// The shelf button the Smart Bookmarks tip points at: the bookmark button when it's on the shelf, the overflow button otherwise.
    weak var smartBookmarksTipAnchor: UIView?
    var smartBookmarksTip: UIViewController?

    private var bannerAdHostingController: PCHostingController<AnyView>?
    private var bannerAdHeightConstraint: NSLayoutConstraint?

    private let analyticsPlaybackHelper = AnalyticsPlaybackHelper.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: NowPlayingPlayerItemViewController, _) in
            #if !APPCLIP
            if FeatureFlag.bannerAdPlayer.enabled {
                controller.updateBannerAdHeight()
            }
            #endif
            controller.updateSize()
        }

        setUpArtworkImageView()

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
        } else {
            showSmartBookmarksTipIfNeeded()
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
        #if !APPCLIP
        dismissSmartBookmarksTip()
        #endif
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
                guard let self else { return }

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

        if LiquidGlass.isEnabled {
            // Render the shelf as a proper pill instead of the default rounded rectangle.
            shelfBg.layer.cornerRadius = shelfBg.bounds.height / 2
        }

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

    private var artworkCornerRadius: CGFloat {
        LiquidGlass.isEnabled ? 16 : 8
    }

    /// Puts the artwork in an aspect-fitting inner view (so `cornerRadius` rounds
    /// the real image) and turns `episodeImage` into the reserved square slot.
    private func setUpArtworkImageView() {
        let artwork = AspectFitArtworkImageView()
        artwork.translatesAutoresizingMaskIntoConstraints = false
        artwork.contentMode = .scaleAspectFill
        artwork.clipsToBounds = true
        artwork.layer.cornerRadius = artworkCornerRadius
        artwork.isAccessibilityElement = true
        artwork.accessibilityTraits = .image
        episodeImage.addSubview(artwork)
        episodeImage.layer.cornerRadius = 0
        artworkImageView = artwork

        // Aspect-fit, centred inside the square slot.
        let fillWidth = artwork.widthAnchor.constraint(equalTo: episodeImage.widthAnchor)
        fillWidth.priority = .defaultHigh
        let fillHeight = artwork.heightAnchor.constraint(equalTo: episodeImage.heightAnchor)
        fillHeight.priority = .defaultHigh
        NSLayoutConstraint.activate([
            artwork.centerXAnchor.constraint(equalTo: episodeImage.centerXAnchor),
            artwork.centerYAnchor.constraint(equalTo: episodeImage.centerYAnchor),
            artwork.widthAnchor.constraint(lessThanOrEqualTo: episodeImage.widthAnchor),
            artwork.heightAnchor.constraint(lessThanOrEqualTo: episodeImage.heightAnchor),
            fillWidth,
            fillHeight,
        ])
    }

    override func willBeAddedToPlayer() {
        if artworkImageView.image == nil, let placeholderArtwork {
            artworkImageView.image = placeholderArtwork
            self.placeholderArtwork = nil
        }
        update(notification: nil)
        addObservers()
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()

        #if !APPCLIP
        if FeatureFlag.bannerAdPlayer.enabled {
            removeBannerAd()
        }
        // Drop any in-flight generated-chapter resolve so a dismissed player can't
        // seek later (matching ChaptersViewController), and clear a skip spinner
        // left mid-resolve so a reused player doesn't reappear with a dimmed button.
        FingerprintTimingManager.shared.cancelPendingChapterResolve()
        resetChapterSkipResolving()
        #endif
    }

    override func themeDidChange() {
        lastShelfLoadState = ShelfLoadState()
        update(notification: nil)
    }

    var shelfIconSize: CGFloat {
        let metrics = UIFontMetrics(forTextStyle: .largeTitle)
        let iconSize = min(45, max(32, metrics.scaledValue(for: 32)))
        return iconSize
    }

    private func updateSize() {
        let iconSize = shelfIconSize
        for view in playerControlsStackView.subviews {
            view.updateSizeConstraints(to: iconSize)
        }
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
        PlaybackManager.shared.trackChapterEvent(.playerPreviousChapterTapped)

        #if !APPCLIP
        // Generated chapters carry reference-timeline starts that dynamic ads have
        // shifted, so resolve the true playback position by fingerprinting before
        // seeking — matching the chapters-list tap flow.
        if GeneratedChapterSeeker.isEnabled {
            // Clear any spinner left over from a resolve this tap supersedes.
            resetChapterSkipResolving()
            if let previous = PlaybackManager.shared.previousPlayableChapter() {
                PlaybackManager.shared.trackChapterSkippedIfNeeded(to: previous)
                GeneratedChapterSeeker.seek(
                    to: previous,
                    startPlayback: false,
                    willBeginResolving: { [weak self] in self?.setChapterSkipResolving(true, forward: false) },
                    didEndResolving: { [weak self] in self?.setChapterSkipResolving(false, forward: false) }
                )
                return
            }
        }
        #endif

        PlaybackManager.shared.skipToPreviousChapter()
    }

    @IBAction func chapterSkipForwardTapped(_ sender: Any) {
        PlaybackManager.shared.trackChapterEvent(.playerNextChapterTapped)

        #if !APPCLIP
        if GeneratedChapterSeeker.isEnabled {
            // Clear any spinner left over from a resolve this tap supersedes.
            resetChapterSkipResolving()
            guard let next = PlaybackManager.shared.nextPlayableChapter() else {
                // No next chapter — respect the producer's end of the last chapter
                // (the same fallback `skipToNextChapter` makes). This isn't a
                // chapter start, so there's nothing to fingerprint-resolve.
                PlaybackManager.shared.skipToEndOfLastChapter()
                return
            }
            PlaybackManager.shared.trackChapterSkippedIfNeeded(to: next)
            GeneratedChapterSeeker.seek(
                to: next,
                startPlayback: false,
                willBeginResolving: { [weak self] in self?.setChapterSkipResolving(true, forward: true) },
                didEndResolving: { [weak self] in self?.setChapterSkipResolving(false, forward: true) }
            )
            return
        }
        #endif

        PlaybackManager.shared.skipToNextChapter()
    }

    #if !APPCLIP
    /// Show/hide a spinner over the tapped chapter-skip button while its generated
    /// chapter is being fingerprint-resolved. The button is dimmed to alpha 0
    /// (which also stops it receiving taps) so a slow resolve can't be double-fired.
    private func setChapterSkipResolving(_ resolving: Bool, forward: Bool) {
        let button = forward ? chapterSkipFwdBtn : chapterSkipBackBtn
        let spinner = forward ? chapterSkipFwdSpinner : chapterSkipBackSpinner
        button?.alpha = resolving ? 0 : 1
        if resolving {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    /// Restore both chapter-skip buttons to idle. Called before starting a new
    /// resolve: a superseded resolve's completion is intentionally dropped (the
    /// `onDemandFlag` identity guard), so `didEndResolving` may never fire to clear
    /// the spinner of the resolve this tap supersedes — leaving it spinning forever.
    private func resetChapterSkipResolving() {
        setChapterSkipResolving(false, forward: true)
        setChapterSkipResolving(false, forward: false)
    }

    private lazy var chapterSkipBackSpinner = makeChapterSkipSpinner(centeredOn: chapterSkipBackBtn)
    private lazy var chapterSkipFwdSpinner = makeChapterSkipSpinner(centeredOn: chapterSkipFwdBtn)

    private func makeChapterSkipSpinner(centeredOn button: UIButton?) -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = ThemeColor.playerContrast01()
        if let button, let container = button.superview {
            container.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
        }
        return spinner
    }
    #endif

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
        guard let artwork = artworkImageView.image else { return }

        let agrume = Agrume(image: artwork, background: .blurred(.regular))
        agrume.show(from: self)
#endif
    }

    @objc private func videoTapped() {
        guard PlaybackManager.shared.currentEpisode != nil else { return }

        if PlaybackManager.shared.shouldRenderVideo() {
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
        guard let episode = PlaybackManager.shared.currentEpisode else { return }

        let options = OptionsPicker(title: nil, themeOverride: .dark)

        let markPlayedOption = OptionAction(label: L10n.markPlayedShort, icon: nil) {
            AnalyticsEpisodeHelper.shared.currentSource = .playerSkipForwardLongPress
            EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        }
        options.addAction(action: markPlayedOption)

        if PlaybackManager.shared.queue.upNextCount() > 0 {
            let skipToNextAction = OptionAction(label: L10n.nextEpisode, icon: nil) {
                let currentlyPlayingEpisode = PlaybackManager.shared.currentEpisode
                PlaybackManager.shared.removeIfPlayingOrQueued(episode: currentlyPlayingEpisode, fireNotification: true, userInitiated: true)
            }
            options.addAction(action: skipToNextAction)
        }

        options.present(from: self)
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

/// A `UIImageView` that constrains itself to its image's aspect ratio, so when
/// aspect-fit in a container its `cornerRadius` rounds the visible image (no mask).
final class AspectFitArtworkImageView: UIImageView {
    private var aspectRatioConstraint: NSLayoutConstraint?

    override var image: UIImage? {
        didSet { updateAspectRatioConstraint() }
    }

    private func updateAspectRatioConstraint() {
        aspectRatioConstraint?.isActive = false
        guard let size = image?.size, size.width > 0, size.height > 0 else {
            aspectRatioConstraint = nil
            return
        }
        let constraint = widthAnchor.constraint(equalTo: heightAnchor, multiplier: size.width / size.height)
        constraint.isActive = true
        aspectRatioConstraint = constraint
    }
}
