import Agrume
import AVKit
import SafariServices
import UIKit

class NowPlayingPlayerItemViewController: PlayerItemViewController {
    var showingCustomImage = false
    var lastChapterIndexRendered = -1

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
            episodeName.style = .playerContrast01
        }
    }

    @IBOutlet var podcastName: ThemeableLabel! {
        didSet {
            podcastName.style = .playerContrast02
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(podcastNameTapped))
            podcastName.addGestureRecognizer(tapGesture)

            podcastName.accessibilityTraits = .button
            podcastName.accessibilityHint = L10n.accessibilityHintPlayerNavigateToPodcastLabel
        }
    }

    @IBOutlet var chapterName: ThemeableLabel! {
        didSet {
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

    let chromecastBtn = PCAlwaysVisibleCastBtn()
    let routePicker = PCRoutePickerView(frame: CGRect.zero)

    private lazy var upNextController = UpNextViewController(source: .nowPlaying)

    lazy var upNextViewController: UIViewController = {
        let controller = SJUIUtils.navController(for: upNextController, iconStyle: .secondaryText01, themeOverride: upNextController.themeOverride)
        controller.modalPresentationStyle = .pageSheet

        return controller
    }()

    var lastShelfLoadState = ShelfLoadState()

    private let analyticsPlaybackHelper = AnalyticsPlaybackHelper.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        let upNextPan = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
        upNextPan.delegate = self
        view.addGestureRecognizer(upNextPan)

        chromecastBtn.inactiveTintColor = ThemeColor.playerContrast02()
        chromecastBtn.addTarget(self, action: #selector(googleCastTapped), for: .touchUpInside)
        chromecastBtn.isPointerInteractionEnabled = true

        routePicker.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Show the overflow menu
        if AnnouncementFlow.current == .bookmarksPlayer {
            overflowTapped()
        }
    }

    private var lastBoundsAdjustedFor = CGRect.zero

    var analyticsSource: AnalyticsSource {
        .player
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // there's some expensive operations below, so only do them if the bounds has actually changed
        if lastBoundsAdjustedFor == view.bounds { return }
        lastBoundsAdjustedFor = view.bounds

        let screenHeight = view.bounds.height
        let spacing: CGFloat = screenHeight > 600 ? 30 : 20
        if playerControlsStackView.spacing != spacing { playerControlsStackView.spacing = spacing }

        let height: CGFloat = screenHeight > 710 ? 100 : 80
        if playPauseHeightConstraint.constant != height { playPauseHeightConstraint.constant = height }
    }

    override func willBeAddedToPlayer() {
        update()
        addObservers()
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()
    }

    override func themeDidChange() {
        lastShelfLoadState = ShelfLoadState()
        update()
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

        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            present(SFSafariViewController(with: url), animated: true)
        }
    }

    @objc private func imageTapped() {
        guard let artwork = episodeImage.image else { return }

        let agrume = Agrume(image: artwork, background: .blurred(.regular))
        agrume.show(from: self)
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

    @objc func googleCastTapped() {
        shelfButtonTapped(.chromecast)

        let themeOverride = Theme.sharedTheme.activeTheme.isDark ? Theme.sharedTheme.activeTheme : .dark
        let castController = CastToViewController(themeOverride: themeOverride)
        let navController = SJUIUtils.navController(for: castController, themeOverride: themeOverride)
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true, completion: nil)
    }
}
