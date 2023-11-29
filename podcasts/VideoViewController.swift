import AVFoundation
import AVKit
import MediaPlayer
import PocketCastsServer
import PocketCastsUtils
import UIKit

class VideoViewController: SimpleNotificationsViewController, AVPictureInPictureControllerDelegate, UIGestureRecognizerDelegate {
    var willAttachPlayer: (() -> Void)?
    var willDeattachPlayer: (() -> Void)?

    @IBOutlet var routePickerView: PCRoutePickerView! {
        didSet {
            routePickerView.tintColor = ThemeColor.contrast01(for: .extraDark)
            routePickerView.activeTintColor = ThemeColor.primaryIcon01Active(for: .extraDark)
            routePickerView.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet var fillScreenBtn: UIButton!

    @IBOutlet var closeFileStackView: UIStackView!
    @IBOutlet var playPauseBtn: PlayPauseButton! {
        didSet {
            playPauseBtn.backgroundColor = UIColor.clear
            playPauseBtn.circleColor = UIColor.clear
            playPauseBtn.playButtonColor = ThemeColor.contrast01(for: .extraDark)
        }
    }

    @IBOutlet var skipForwardBtn: SkipButton! {
        didSet {
            skipForwardBtn.skipBack = false
            skipForwardBtn.longPressed = { [weak self] in
                self?.skipForwardLongPressed()
            }
        }
    }

    @IBOutlet var skipBackBtn: SkipButton! {
        didSet {
            skipBackBtn.skipBack = true
        }
    }

    @IBOutlet var timeSlider: TimeSlider! {
        didSet {
            timeSlider.delegate = self
            timeSlider.shouldPopupOnDrag = true
            timeSlider.topOffset = 0
            timeSlider.sidePadding = 38 as CGFloat
        }
    }

    @IBOutlet var timeElapsed: ThemeableLabel! {
        didSet {
            timeElapsed.style = .playerContrast02
            timeElapsed.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: UIFont.Weight.medium)
        }
    }

    @IBOutlet var timeRemaining: ThemeableLabel! {
        didSet {
            timeRemaining.style = .playerContrast02
            timeRemaining.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: UIFont.Weight.medium)
        }
    }

    var controlsDisabled = false
    var showHideTimer: Timer?
    var controlsShowing = true

    @IBOutlet var videoPlayerView: VideoPlayerView! {
        didSet {
            let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(videoViewDoubleTapped))
            doubleTapGesture.numberOfTapsRequired = 2

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoViewTapped))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.require(toFail: doubleTapGesture)

            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
            panGesture.delegate = self
            videoPlayerView.addGestureRecognizer(doubleTapGesture)
            videoPlayerView.addGestureRecognizer(tapGesture)
            videoPlayerView.addGestureRecognizer(panGesture)
        }
    }

    @IBOutlet var pipButton: UIButton!

    @IBOutlet var airplayButton: UIButton!
    @IBOutlet var castButton: PCGoogleCastButton!

    private var pipController: AVPictureInPictureController?
    @IBOutlet var controlsOverlay: UIView! {
        didSet {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
            panGesture.delegate = self
            controlsOverlay.addGestureRecognizer(panGesture)

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoViewTapped))
            controlsOverlay.addGestureRecognizer(tapGesture)
        }
    }

    deinit {
        teardownPictureInPicturePlayback()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let skipBackAmount = ServerSettings.skipBackTime()
        skipBackBtn.skipAmount = skipBackAmount

        let skipFwdAmount = ServerSettings.skipForwardTime()
        skipForwardBtn.skipAmount = skipFwdAmount
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        attachPlayer()

        update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addUiNotificationObservers()
        if PlaybackManager.shared.playing() {
            startHideControlsTimer()
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        willDeattachPlayer?()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        videoPlayerView.player = nil
        removeAllCustomObservers()

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    // MARK: - Actions

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func fillScreenTapped(_ sender: Any) {
        toggleFillScreen()
    }

    @IBAction func skipBackTapped(_ sender: Any) {
        if PlaybackManager.shared.playing() { startHideControlsTimer() }

        PlaybackManager.shared.skipBack()
    }

    @IBAction func playPauseTapped(_ sender: Any) {
        let currentlyPlaying = PlaybackManager.shared.playing()
        HapticsHelper.triggerPlayPauseHaptic()
        if currentlyPlaying {
            PlaybackManager.shared.pause()
            stopHideControlsTimer()
        } else {
            PlaybackManager.shared.play()
            startHideControlsTimer()
        }
    }

    @IBAction func skipForwardTapped(_ sender: Any) {
        if PlaybackManager.shared.playing() { startHideControlsTimer() }
        PlaybackManager.shared.skipForward()
    }

    private func skipForwardLongPressed() {
        guard let episode = PlaybackManager.shared.currentEpisode() else { return }

        let options = OptionsPicker(title: nil, themeOverride: .dark, portraitOnly: false)

        let markPlayedOption = OptionAction(label: L10n.markPlayedShort, icon: nil) {
            AnalyticsEpisodeHelper.shared.currentSource = .videoPlayerSkipForwardLongPress
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

    // MARK: - Picture In Picture

    @IBAction func pictureInPictureTapped(_ sender: Any) {
        guard let pipController = pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    private func setupPictureInPicturePlayback() {
        if let videoPlayerView = videoPlayerView, AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: videoPlayerView.playerLayer)
            pipController?.delegate = self
            pipButton.isHidden = false
        } else {
            pipButton.isHidden = true
        }
    }

    private func teardownPictureInPicturePlayback() {
        if let pipController = pipController {
            pipController.delegate = nil
        }

        pipController = nil
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        disableControls()
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        enableControls()
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("PiP Did Fail")
    }

    // MARK: - Event Handling

    private func addUiNotificationObservers() {
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(progressUpdated))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(update))
        addCustomObserver(Constants.Notifications.videoPlaybackEngineSwitched, selector: #selector(videoPlaybackEngineSwitched))
        addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(playbackFinished))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(trackChanged))
        addCustomObserver(Constants.Notifications.googleCastStatusChanged, selector: #selector(update))
    }

    private func removeUiNotificationObservers() {
        removeAllCustomObservers()
    }

    @objc private func playbackFinished() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func progressUpdated() {
        if timeSlider.isScrubbing() || PlaybackManager.shared.isSeeking() { return }

        updateUpTo(upTo: PlaybackManager.shared.currentTime(), duration: PlaybackManager.shared.duration(), moveSlider: true)
    }

    @objc private func trackChanged() {
        guard let currentEpisode = PlaybackManager.shared.currentEpisode(), currentEpisode.videoPodcast() else {
            dismiss(animated: true, completion: nil)
            return
        }

        // if we're on a different video we need to attach the new player, the old will most likely have been replaced in the transition
        attachPlayer()
        update()
    }

    @objc private func videoPlaybackEngineSwitched() {
        // grab the new player and attach it
        attachPlayer()
        update()
    }

    // MARK: - Updates

    @objc private func update() {
        updatePlayPauseButton()
        progressUpdated()
        updateFillScreenBtn()
    }

    private func updateFillScreenBtn() {
        let imageName = videoPlayerView.gravity == .resizeAspect ? "video-expand" : "video-collapse"
        fillScreenBtn.setImage(UIImage(named: imageName), for: .normal)
    }

    private func updatePlayPauseButton() {
        playPauseBtn.isPlaying = PlaybackManager.shared.playing()
    }

    func updateUpTo(upTo: TimeInterval, duration: TimeInterval, moveSlider: Bool) {
        let remaining = max(0, duration - upTo)
        updateTimeLabels(upTo: upTo, remaining: remaining)

        if moveSlider {
            timeSlider.totalDuration = duration
            timeSlider.currentTime = upTo
        }
    }

    private func attachPlayer() {
        willAttachPlayer?()
        videoPlayerView.player = PlaybackManager.shared.internalPlayerForVideoPlayback()
        setupPictureInPicturePlayback()
    }

    private func updateTimeLabels(upTo: TimeInterval, remaining: TimeInterval) {
        timeElapsed.text = TimeFormatter.shared.playTimeFormat(time: upTo)
        timeRemaining.text = "-\(TimeFormatter.shared.playTimeFormat(time: remaining))"
    }

    func toggleFillScreen() {
        videoPlayerView.gravity = videoPlayerView.gravity == .resizeAspect ? .resizeAspectFill : .resizeAspect
        updateFillScreenBtn()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    // MARK: - Swipe to close

    // The closeOverlay and controlOverlay are anchored to the safe area
    // when we move the view the overlays flicker
    // To prevent this, anchor to the view instead of the safe area
    var initialTouchPoint = CGPoint(x: 0, y: 0)

    private static let pullDownThreshold: CGFloat = 100

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if timeSlider.isScrubbing() { return false }

        guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }

        let velocity = recognizer.velocity(in: view)
        let vertical = abs(velocity.y) > abs(velocity.x)

        if !vertical { return false }

        return velocity.y > 0 // we are only looking for swipe down gestures
    }

    @IBOutlet var closeToViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var closeToSafeTopConstraint: NSLayoutConstraint!

    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: view?.window)

        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint

            closeToViewTopConstraint.constant = closeFileStackView.frame.minY
            closeToSafeTopConstraint.isActive = false
            closeToViewTopConstraint.isActive = true
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: view.frame.size.width, height: view.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > VideoViewController.pullDownThreshold {
                videoPlayerView.isHidden = true
                dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)

                }, completion: { (_: Bool) in
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                    self.closeToSafeTopConstraint.isActive = true
                    self.closeToViewTopConstraint.isActive = false
                })
            }
        }
    }
}
