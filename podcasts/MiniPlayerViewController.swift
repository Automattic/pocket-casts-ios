import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SwiftUI

class MiniPlayerViewController: SimpleNotificationsViewController {
    enum PlayerOpenState {
        case closed, beingDragged, open, animating
    }

    var playerOpenState = PlayerOpenState.closed

    @IBOutlet var playPauseBtn: PlayPauseButton!
    @IBOutlet var skipBackBtn: UIButton!
    @IBOutlet var skipFwdBtn: UIButton!

    @IBOutlet var skipBackBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet var playPauseBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet var skipFwdBtnWidthConstraint: NSLayoutConstraint!

    @IBOutlet var upNextBtn: UpNextButton!

    @IBOutlet var playbackProgressView: ProgressLine!

    @IBOutlet var podcastArtwork: PodcastImageView!
    @IBOutlet var podcastArtworkWidthConstraint: NSLayoutConstraint!
    @IBOutlet var podcastArtworkHeightConstraint: NSLayoutConstraint!
    @IBOutlet var mainView: UIView!
    @IBOutlet var shadowView: UIView!

    @IBOutlet var gradientView: MiniPlayerGradientView!

    private var lastEpisodeUuidImageLoaded = ""
    private var lastEpisodeUuidAutoOpened = ""
    private var showingChapterArtwork = false
    var fullScreenPlayer: PlayerContainerViewController?

    /// Carries the upward pan velocity from the open-gesture recognizer to
    /// the transition delegate so the present animation can match the flick's
    /// momentum. Negative = upward (the gesture direction). Reset to 0 after
    /// the delegate consumes it so a subsequent tap-driven open starts at rest.
    var pendingPresentVelocity: CGFloat = 0

    var panUpRecognizer: UIPanGestureRecognizer!
    var longPressRecognizer: UILongPressGestureRecognizer!

    /// Tracks whether the user tapped an action from the long-press context
    /// menu (Liquid Glass path). Used to decide whether to fire the
    /// "menu dismissed" analytics event when the menu closes.
    var longPressContextMenuActionSelected = false

    var heightConstraint: NSLayoutConstraint?

    weak var hostTabBarController: UITabBarController?

    var upNextViewController: UpNextViewController?

    private let analyticsPlaybackHelper = AnalyticsPlaybackHelper.shared

    private var episodeTitleLabel: MiniPlayerScrollingTitleView?
    private var timeLeftModel: MiniPlayerTimeLeftModel?
    private var timeLeftHostingController: UIHostingController<MiniPlayerTimeLeftView>?
    private var glassProgressView: MiniPlayerGlassProgressView?

    private var glassButtonStack: UIStackView?
    private var accessoryEnvironmentConstraints: [NSLayoutConstraint] = []
    private var accessoryWidthConstraint: NSLayoutConstraint?
    private var accessoryWindowWidth: CGFloat = 0

    private var compactTextStack: UIStackView?
    private var compactBottomRow: UIStackView?
    private var titleVibrancy: UIVisualEffectView?
    private var timeLeftVibrancy: UIVisualEffectView?
    private var largeRow: UIStackView?
    private var largeTimeRow: UIStackView?
    private var largeInfoStack: UIStackView?
    private var subtitleLabel: UILabel?
    private var elapsedLabel: UILabel?
    private var remainingLabel: UILabel?
    private var transcriptButton: UIButton?
    private var compactConstraints: [NSLayoutConstraint] = []
    private var largeConstraints: [NSLayoutConstraint] = []
    private(set) var isTranscriptAvailable = false

    /// True while the large screen layout (title and podcast, elapsed and remaining
    /// time around the progress bar, transcript and bookmark buttons) is installed.
    private(set) var isLargeLayoutApplied = false

    /// Same as `forcedInlineLayout`, for the large screen layout.
    private var forcedLargeLayout: Bool?

    /// Wraps `content` in a vibrancy effect so it blends with the tab accessory's glass.
    private static func makeVibrancyWrapper(style: UIVibrancyEffectStyle, content: UIView) -> UIVisualEffectView {
        let vibrancy = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemChromeMaterial), style: style)
        let wrapper = UIVisualEffectView(effect: vibrancy)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        wrapper.contentView.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: wrapper.contentView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: wrapper.contentView.trailingAnchor),
            content.topAnchor.constraint(equalTo: wrapper.contentView.topAnchor),
            content.bottomAnchor.constraint(equalTo: wrapper.contentView.bottomAnchor),
        ])
        return wrapper
    }

    /// When set, the next time-left value update is wrapped in `withAnimation`
    /// so SwiftUI's numeric-text transition rolls the digits. Set by skip
    /// back/forward and consumed on the first resulting change so only
    /// deliberate skips animate (not the per-second progress ticks).
    private var animateNextTimeLeftChange = false

    /// When set, overrides the live `tabAccessoryEnvironment` trait so the
    /// inline/regular layout can be forced regardless of where the view is
    /// hosted. Used by `PlayerZoomAnimator` to make the snapshot clone match
    /// the real mini player's layout even though the clone isn't inside a
    /// `UITabAccessory`.
    private var forcedInlineLayout: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()

        addGestureRecognizers()

        view.isHidden = false

        setupAccessibility()

        if #available(iOS 26.0, *) {
            setupLiquidGlassLayout()
        } else {
            setupCorners()
        }
        addUINotificationObservers()
        playbackStateDidChange()
        themeChanged()
    }

    private func setupAccessibility() {
        for artworkView in [podcastArtwork, podcastArtwork.superview] {
            artworkView?.accessibilityLabel = L10n.accessibilityMiniPlayer
            artworkView?.accessibilityHint = L10n.accessibilityMiniPlayerHint
        }
        skipBackBtn.accessibilityLabel = L10n.skipBack
        skipFwdBtn.accessibilityLabel = L10n.skipForward
        upNextBtn.accessibilityLabel = L10n.accessibilityUpNextList
    }

    private func setupCorners() {
        mainView.layer.cornerRadius = MiniPlayerShadowView.Constants.shadowCornerRadius
        mainView.layer.masksToBounds = true
    }

    @available(iOS 26.0, *)
    private func setupLiquidGlassLayout() {
        gradientView.isHidden = true
        shadowView.isHidden = true
        mainView.isHidden = true
        playbackProgressView.isHidden = true
        upNextBtn.isHidden = true

        view.backgroundColor = .clear

        podcastArtwork.removeFromSuperview()
        skipBackBtn.removeFromSuperview()
        playPauseBtn.removeFromSuperview()
        skipFwdBtn.removeFromSuperview()

        podcastArtworkWidthConstraint.constant = 32
        podcastArtworkHeightConstraint.constant = 32

        podcastArtwork.translatesAutoresizingMaskIntoConstraints = false
        skipBackBtn.translatesAutoresizingMaskIntoConstraints = false
        playPauseBtn.translatesAutoresizingMaskIntoConstraints = false
        skipFwdBtn.translatesAutoresizingMaskIntoConstraints = false

        podcastArtwork.layer.cornerRadius = 6
        podcastArtwork.layer.masksToBounds = true

        playPauseBtn.useSymbolImage(pointSize: 30)

        // The skip glyphs read a touch heavy next to the smaller glass
        // play/pause button, so scale the (template) assets down slightly.
        for button in [skipBackBtn, skipFwdBtn] {
            guard let button, let image = button.image(for: .normal) else { continue }
            let target = CGSize(width: image.size.width, height: image.size.height)
            button.setImage(image.resizeProportionally(to: target).withRenderingMode(.alwaysTemplate), for: .normal)
        }

        let title = MiniPlayerScrollingTitleView()
        title.font = .font(ofSize: 13, weight: .medium, scalingWith: .footnote, maxSizeCategory: .extraExtraLarge)
        episodeTitleLabel = title
        let titleVibrancy = Self.makeVibrancyWrapper(style: .label, content: title)

        // Hosted SwiftUI so the time-left digits can use the native
        // `.numericText` content transition when the user skips.
        let timeLeftModel = MiniPlayerTimeLeftModel()
        let timeLeftHost = UIHostingController(rootView: MiniPlayerTimeLeftView(model: timeLeftModel))
        timeLeftHost.view.backgroundColor = .clear
        timeLeftHost.sizingOptions = .intrinsicContentSize
        timeLeftHost.safeAreaRegions = []
        addChild(timeLeftHost)

        self.timeLeftModel = timeLeftModel
        self.timeLeftHostingController = timeLeftHost

        let timeLeftVibrancy = Self.makeVibrancyWrapper(style: .secondaryLabel, content: timeLeftHost.view)

        let progressView = MiniPlayerGlassProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        glassProgressView = progressView

        let bottomRow = UIStackView(arrangedSubviews: [progressView, timeLeftVibrancy])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.spacing = 6
        bottomRow.semanticContentAttribute = .playback

        progressView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        progressView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        timeLeftHost.view.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLeftHost.view.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleVibrancy, bottomRow])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        let buttonStack = UIStackView(arrangedSubviews: [skipBackBtn, playPauseBtn, skipFwdBtn])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.alignment = .fill
        buttonStack.semanticContentAttribute = .playback
        glassButtonStack = buttonStack

        timeLeftHost.didMove(toParent: self)

        compactTextStack = textStack
        compactBottomRow = bottomRow
        self.titleVibrancy = titleVibrancy
        self.timeLeftVibrancy = timeLeftVibrancy

        compactConstraints = [
            podcastArtwork.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            podcastArtwork.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: podcastArtwork.trailingAnchor, constant: 8),
            textStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            {
                let constraint = textStack.trailingAnchor.constraint(lessThanOrEqualTo: buttonStack.leadingAnchor, constant: 2)
                constraint.priority = UILayoutPriority(999)
                return constraint
            }(),

            buttonStack.topAnchor.constraint(equalTo: view.topAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 56),
        ]

        progressView.heightAnchor.constraint(equalToConstant: 5).isActive = true

        setupLargeLayout(buttonStack: buttonStack)
        applyLayoutVariant(isLarge: false)

        view.registerForTraitChanges([UITraitTabAccessoryEnvironment.self]) { (view: UIView, _) in
            view.setNeedsUpdateConstraints()
        }
    }

    /// The large screen layout is used when the accessory is hosted in a regular width window
    /// and is wide enough to fit it.
    private var wantsLargeLayout: Bool {
        forcedLargeLayout ?? (hostTabBarController != nil
            && view.window?.traitCollection.horizontalSizeClass == .regular
            && view.bounds.width >= Self.largeLayoutMinimumWidth)
    }

    private static let largeLayoutMinimumWidth: CGFloat = 560

    override func updateViewConstraints() {
        if #available(iOS 26.0, *), let glassProgressView {
            applyLayoutVariant(isLarge: wantsLargeLayout)

            NSLayoutConstraint.deactivate(accessoryEnvironmentConstraints)
            accessoryEnvironmentConstraints = []
            if !isLargeLayoutApplied, let glassButtonStack {
                let isInline = forcedInlineLayout ?? (view.traitCollection.tabAccessoryEnvironment == .inline)
                let progressWidth = glassProgressView.widthAnchor.constraint(equalToConstant: isInline ? 34 : 52)
                progressWidth.priority = UILayoutPriority(750)
                accessoryEnvironmentConstraints = [
                    progressWidth,
                    glassButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
                ]
                NSLayoutConstraint.activate(accessoryEnvironmentConstraints)
            }
            updateAccessoryPreferredWidth()
        }
        super.updateViewConstraints()
    }

    /// On regular width the system stretches an accessory that states no preferred width across the
    /// whole bar, so ask for a centered pill like the system apps do.
    @available(iOS 26.0, *)
    private func updateAccessoryPreferredWidth() {
        accessoryWidthConstraint?.isActive = false
        accessoryWidthConstraint = nil
        accessoryWindowWidth = view.window?.bounds.width ?? 0
        guard hostTabBarController != nil,
              view.window?.traitCollection.horizontalSizeClass == .regular,
              accessoryWindowWidth > 0 else { return }
        let constraint = view.widthAnchor.constraint(equalToConstant: min(780, max(accessoryWindowWidth - 32, Self.largeLayoutMinimumWidth)))
        constraint.priority = UILayoutPriority(999)
        constraint.isActive = true
        accessoryWidthConstraint = constraint
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let windowWidth = view.window?.bounds.width, windowWidth != accessoryWindowWidth || wantsLargeLayout != isLargeLayoutApplied {
            view.setNeedsUpdateConstraints()
        }

        guard !isLargeLayoutApplied, let timeLeftHost = timeLeftHostingController?.view, let glassButtonStack else {
            return
        }

        let timeLeftFrame = timeLeftHost.convert(timeLeftHost.bounds, to: view)
        let buttonsFrame = glassButtonStack.convert(glassButtonStack.bounds, to: view).insetBy(dx: 12, dy: 0)

        timeLeftHost.alpha = timeLeftFrame.intersects(buttonsFrame) ? 0 : 1
    }

    /// Builds the views that only the large screen layout shows. The views both layouts
    /// share are moved between the two by `applyLayoutVariant`.
    @available(iOS 26.0, *)
    private func setupLargeLayout(buttonStack: UIStackView) {
        let subtitle = UILabel()
        subtitle.font = .font(ofSize: 11, weight: .regular, scalingWith: .caption2, maxSizeCategory: .extraExtraLarge)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.textColor = .label
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel = subtitle
        let subtitleVibrancy = Self.makeVibrancyWrapper(style: .secondaryLabel, content: subtitle)

        let infoStack = UIStackView(arrangedSubviews: [subtitleVibrancy])
        infoStack.axis = .vertical
        infoStack.alignment = .fill
        infoStack.spacing = 1
        infoStack.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        infoStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        largeInfoStack = infoStack

        let elapsed = makeTimeLabel()
        let remaining = makeTimeLabel()
        elapsedLabel = elapsed
        remainingLabel = remaining
        let elapsedVibrancy = Self.makeVibrancyWrapper(style: .secondaryLabel, content: elapsed)
        let remainingVibrancy = Self.makeVibrancyWrapper(style: .secondaryLabel, content: remaining)
        for wrapper in [elapsedVibrancy, remainingVibrancy] {
            wrapper.setContentHuggingPriority(.required, for: .horizontal)
            wrapper.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        let timeRow = UIStackView(arrangedSubviews: [elapsedVibrancy, remainingVibrancy])
        timeRow.axis = .horizontal
        timeRow.alignment = .center
        timeRow.spacing = 8
        timeRow.semanticContentAttribute = .playback
        largeTimeRow = timeRow

        let transcript = makeTrailingButton(image: UIImage(named: "transcript")?.withRenderingMode(.alwaysTemplate), label: L10n.transcript, action: #selector(transcriptTapped))
        let bookmark = makeTrailingButton(image: Self.bookmarkGlyph(), label: L10n.addBookmark, action: #selector(bookmarkTapped))
        transcriptButton = transcript

        // The artwork, the title, the playback buttons and the progress bar are shared with the
        // compact layout and inserted by `applyLayoutVariant`.
        let row = UIStackView(arrangedSubviews: [infoStack, timeRow, transcript, bookmark])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.setCustomSpacing(18, after: timeRow)
        row.setCustomSpacing(4, after: transcript)
        largeRow = row

        largeConstraints = [
            row.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17),
            row.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17),
            row.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            infoStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.22),
            buttonStack.heightAnchor.constraint(equalToConstant: 50),
        ]
    }

    @available(iOS 26.0, *)
    private func makeTimeLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .monospacedDigitSystemFont(ofSize: 11, weight: .regular), maximumPointSize: 15)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    /// The bookmark asset's line is thicker than the transcript's, so draw it with the same 2pt line.
    private static func bookmarkGlyph() -> UIImage {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 4.45, y: 20.6))
        path.addLine(to: CGPoint(x: 4.45, y: 5.5))
        path.addArc(withCenter: CGPoint(x: 6.95, y: 5.5), radius: 2.5, startAngle: .pi, endAngle: 1.5 * .pi, clockwise: true)
        path.addLine(to: CGPoint(x: 17.05, y: 3))
        path.addArc(withCenter: CGPoint(x: 17.05, y: 5.5), radius: 2.5, startAngle: 1.5 * .pi, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: 19.55, y: 20.6))
        path.addLine(to: CGPoint(x: 13.2, y: 15))
        path.addQuadCurve(to: CGPoint(x: 10.8, y: 15), controlPoint: CGPoint(x: 12, y: 14))
        path.close()
        path.lineWidth = 2
        path.lineJoinStyle = .round

        return UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { _ in
            UIColor.black.setStroke()
            path.stroke()
        }.withRenderingMode(.alwaysTemplate)
    }

    @available(iOS 26.0, *)
    private func makeTrailingButton(image: UIImage?, label: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.isPointerInteractionEnabled = true
        button.accessibilityLabel = label
        button.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
        return button
    }

    /// Moves the views both layouts share into the compact or the large screen layout.
    @available(iOS 26.0, *)
    private func applyLayoutVariant(isLarge: Bool) {
        guard let glassButtonStack, let compactTextStack, let compactBottomRow, let largeRow, let largeTimeRow, let largeInfoStack,
              let titleVibrancy, let timeLeftVibrancy, let glassProgressView else { return }
        let isInstalled = largeRow.superview != nil || compactTextStack.superview != nil
        guard isLarge != isLargeLayoutApplied || !isInstalled else { return }

        isLargeLayoutApplied = isLarge
        NSLayoutConstraint.deactivate(compactConstraints + largeConstraints)

        for shared in [podcastArtwork, glassButtonStack, glassProgressView, titleVibrancy, timeLeftVibrancy] as [UIView] {
            shared.removeFromSuperview()
        }
        compactTextStack.removeFromSuperview()
        largeRow.removeFromSuperview()

        let buttonWidth: CGFloat
        if isLarge {
            buttonWidth = 40
            podcastArtworkWidthConstraint.constant = 40
            podcastArtworkHeightConstraint.constant = 40
            podcastArtwork.layer.cornerRadius = 8
            episodeTitleLabel?.font = .font(ofSize: 12, weight: .medium, scalingWith: .footnote, maxSizeCategory: .extraExtraLarge)

            largeInfoStack.insertArrangedSubview(titleVibrancy, at: 0)
            largeRow.insertArrangedSubview(podcastArtwork, at: 0)
            largeRow.insertArrangedSubview(glassButtonStack, at: 2)
            largeTimeRow.insertArrangedSubview(glassProgressView, at: 1)
            largeRow.setCustomSpacing(10, after: podcastArtwork)
            checkTranscriptAvailability()
            largeRow.setCustomSpacing(12, after: largeInfoStack)
            largeRow.setCustomSpacing(14, after: glassButtonStack)
            view.addSubview(largeRow)
            NSLayoutConstraint.activate(largeConstraints)
        } else {
            buttonWidth = 47
            podcastArtworkWidthConstraint.constant = 32
            podcastArtworkHeightConstraint.constant = 32
            podcastArtwork.layer.cornerRadius = 6
            episodeTitleLabel?.font = .font(ofSize: 13, weight: .medium, scalingWith: .footnote, maxSizeCategory: .extraExtraLarge)

            compactTextStack.insertArrangedSubview(titleVibrancy, at: 0)
            compactBottomRow.insertArrangedSubview(glassProgressView, at: 0)
            compactBottomRow.insertArrangedSubview(timeLeftVibrancy, at: 1)
            view.addSubview(podcastArtwork)
            view.addSubview(compactTextStack)
            view.addSubview(glassButtonStack)
            NSLayoutConstraint.activate(compactConstraints)
        }

        skipBackBtnWidthConstraint.constant = buttonWidth
        playPauseBtnWidthConstraint.constant = buttonWidth
        skipFwdBtnWidthConstraint.constant = buttonWidth

        updateTranscriptAvailabilityUI()
        updateTitle()
        playbackProgressDidChange()
    }

    deinit {
        removeAllCustomObservers()
    }

    /// Aligns this controller's scrolling title with another's, so the
    /// snapshot clone built for the zoom transition picks up the live mini
    /// player's scroll phase. Must be called after the clone is in a window.
    func synchronizeScrollingTitleAnimation(with other: MiniPlayerViewController) {
        guard let mine = episodeTitleLabel, let theirs = other.episodeTitleLabel else { return }
        mine.synchronizeAnimation(with: theirs)
    }

    /// Forces the Liquid Glass layout to use the inline (collapsed tab bar) or
    /// regular spacing, bypassing the live `tabAccessoryEnvironment` trait.
    /// Used by the zoom transition to make the snapshot clone match the real
    /// mini player when it's hosted in an inline tab accessory.
    func setForcedInlineLayout(_ inline: Bool) {
        forcedInlineLayout = inline
        view.setNeedsUpdateConstraints()
    }

    /// Forces the large screen layout on or off, bypassing the window's size class. Used by the
    /// zoom transition to make the snapshot clone match the real mini player.
    func setForcedLargeLayout(_ large: Bool) {
        forcedLargeLayout = large
        if #available(iOS 26.0, *) {
            applyLayoutVariant(isLarge: large)
        }
        view.setNeedsUpdateConstraints()
    }

    @objc private func transcriptTapped() {
        guard isTranscriptAvailable else {
            Toast.show(TranscriptError.notAvailable.localizedDescription)
            return
        }

        openFullScreenPlayer { [weak self] in
            self?.fullScreenPlayer?.nowPlayingItem.openTranscript()
        }
    }

    @objc private func bookmarkTapped() {
        let action = PlayerAction.addBookmark
        guard action.isUnlocked else {
            action.paidFeature?.presentUpgradeController(from: self, source: .bookmarksShelfAction)
            return
        }

        PlaybackManager.shared.bookmark(source: .miniPlayer)
    }

    @objc private func transcriptAvailabilityDidChange(_ notification: Notification) {
        guard let episodeUuid = notification.userInfo?["episodeUuid"] as? String,
              let isAvailable = notification.userInfo?["isAvailable"] as? Bool,
              episodeUuid == PlaybackManager.shared.currentEpisode?.uuid else { return }

        isTranscriptAvailable = isAvailable
        updateTranscriptAvailabilityUI()
    }

    @objc private func playbackTrackDidChange() {
        isTranscriptAvailable = false
        updateTranscriptAvailabilityUI()
        checkTranscriptAvailability()
    }

    /// Only the hosted mini player in the large screen layout shows the transcript button, so it is the only one to look it up.
    private func checkTranscriptAvailability() {
        guard isLargeLayoutApplied, hostTabBarController != nil else { return }
        (PlaybackManager.shared.currentEpisode as? Episode)?.checkTranscriptAvailability()
    }

    /// Lets the zoom transition clone show the button the way the live mini player does.
    func copyTranscriptAvailability(from other: MiniPlayerViewController) {
        isTranscriptAvailable = other.isTranscriptAvailable
        updateTranscriptAvailabilityUI()
    }

    private func updateTranscriptAvailabilityUI() {
        transcriptButton?.alpha = isTranscriptAvailable ? 1 : 0.4
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
        if let timeLeftModel {
            timeLeftModel.countsDown = false
            animateNextTimeLeftChange = true
        }
        PlaybackManager.shared.skipBack()
        animateSkipButton(skipBackBtn, clockwise: false)
    }

    @IBAction func skipForwardTapped(_ sender: Any) {
        analyticsPlaybackHelper.currentSource = analyticsSource
        HapticsHelper.triggerSkipForwardHaptic()
        if let timeLeftModel {
            timeLeftModel.countsDown = true
            animateNextTimeLeftChange = true
        }
        PlaybackManager.shared.skipForward()
        animateSkipButton(skipFwdBtn, clockwise: true)
    }

    private func animateSkipButton(_ button: UIButton, clockwise: Bool) {
        guard let imageView = button.imageView else { return }

        if UIAccessibility.isReduceMotionEnabled {
            let alpha = CAKeyframeAnimation(keyPath: "opacity")
            alpha.values = [1.0, 0.4, 1.0]
            alpha.keyTimes = [0, 0.4, 1]
            alpha.duration = 0.3
            imageView.layer.add(alpha, forKey: "skipAlpha")
            return
        }

        let duration: CFTimeInterval = 0.7

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = clockwise ? CGFloat.pi * 2 : -CGFloat.pi * 2
        rotation.duration = duration
        rotation.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1.0)
        imageView.layer.add(rotation, forKey: "skipRotation")

        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [1.0, 0.85, 1.0]
        scale.keyTimes = [0, 0.4, 1]
        scale.duration = duration
        scale.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
        ]
        imageView.layer.add(scale, forKey: "skipScale")
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
        // Undo the blanking `PlayerZoomAnimator` applies to the mini player when
        // presenting the full screen player. The animated dismissal already
        // restores this itself, so re-applying it here is a no-op there, but it
        // keeps the mini player visible after any teardown path.
        view.alpha = 1
        view.subviews.forEach { $0.alpha = 1 }

        guard rootViewController() != nil else { return }

        rootViewController()?.setNeedsStatusBarAppearanceUpdate()
        rootViewController()?.setNeedsUpdateOfHomeIndicatorAutoHidden()

        fullScreenPlayer?.view.removeFromSuperview()
        fullScreenPlayer = nil

        // update the mini player on full screen player close
        playbackStateDidChange()
        playbackProgressDidChange()
    }

    /// A `dismiss(animated: false)` anywhere up the presentation chain
    /// (notification taps, deep links, stacked-sheet teardowns) never consults
    /// the transitioning delegate, so the animators' dismiss completions —
    /// which restore the mini player and close out `playerOpenState` — don't
    /// run, leaving the mini player permanently empty and frozen. Called from
    /// the player's presentation controller only for those non-animated
    /// teardowns; animated dismissals are fully handled by the animators.
    func fullScreenPlayerDidDismiss(_ player: PlayerContainerViewController) {
        guard fullScreenPlayer == nil || fullScreenPlayer === player else { return }

        playerOpenState = .closed
        finishedWithFullScreenPlayer()
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
        addCustomObserver(Constants.Notifications.videoPlaybackEngineSwitched, selector: #selector(videoPlaybackEngineSwitched))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(playbackStateDidChange))
        addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(playbackStateDidChange))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(playbackStateDidChange))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(playbackTrackDidChange))
        addCustomObserver(Constants.Notifications.episodeTranscriptAvailabilityChanged, selector: #selector(transcriptAvailabilityDidChange(_:)))
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(playbackProgressDidChange))
        addCustomObserver(Constants.Notifications.chapterSelectionChanged, selector: #selector(playbackProgressDidChange))
        addCustomObserver(Constants.Notifications.googleCastStatusChanged, selector: #selector(playbackStateDidChange))
        addCustomObserver(Constants.Notifications.statusBarHeightChanged, selector: #selector(statusBarHeightDidChange))

        addCustomObserver(Constants.Notifications.podcastImageReCacheRequired, selector: #selector(updateRequired))

        addCustomObserver(.episodeEmbeddedArtworkLoaded, selector: #selector(updateRequired))

        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(upNextListChanged))
        addCustomObserver(Constants.Notifications.podcastDeleted, selector: #selector(upNextListChanged))

        addCustomObserver(UIApplication.didBecomeActiveNotification, selector: #selector(playbackStateDidChange))

        addCustomObserver(Constants.Notifications.themeChanged, selector: #selector(themeChanged))
        addCustomObserver(Constants.Notifications.currentlyPlayingEpisodeUpdated, selector: #selector(updateRequired))

        addCustomObserver(Constants.Notifications.podcastChapterChanged, selector: #selector(chapterDidChange))
        addCustomObserver(Constants.Notifications.podcastChaptersDidUpdate, selector: #selector(chapterDidChange))
    }

    func rootViewController() -> MainTabBarController? {
        if let controller = view.window?.rootViewController as? MainTabBarController {
            return controller
        }

        return nil
    }

    func miniPlayerShowing() -> Bool {
        assert(!LiquidGlass.isEnabled, "Should never be used when Liquid Glass is on")
        return !view.isHidden
    }

    private func setupForEpisode(_ episode: BaseEpisode) {
        updateColors()
        updateArtwork(for: episode)
        updateTitle(for: episode)
    }

    /// Shows the current chapter's embedded artwork when available, falling
    /// back to the episode artwork otherwise — matching the full screen player.
    private func updateArtwork(for episode: BaseEpisode, forceReload: Bool = false) {
        let chapters = PlaybackManager.shared.currentChapters
        if PlaybackManager.shared.chapterCount() != 0, let artwork = chapters.artwork {
            showingChapterArtwork = true
            podcastArtwork.setImageManually(image: artwork, size: .list)
            return
        }

        let needsReload = forceReload || showingChapterArtwork || lastEpisodeUuidImageLoaded != episode.uuid
        showingChapterArtwork = false
        guard needsReload else { return }

        lastEpisodeUuidImageLoaded = episode.uuid
        if let userEpisode = episode as? UserEpisode {
            podcastArtwork.setUserEpisode(uuid: userEpisode.uuid, size: .list)
        } else {
            podcastArtwork.setBaseEpisode(episode: episode, size: .list)
        }
    }

    /// Shows the current chapter title when the episode has chapters, falling
    /// back to the episode title otherwise — matching the full screen player.
    private func updateTitle(for episode: BaseEpisode? = PlaybackManager.shared.currentEpisode) {
        guard let episodeTitleLabel, let episode else { return }

        let chapters = PlaybackManager.shared.currentChapters
        let newTitle: String?
        if PlaybackManager.shared.chapterCount() != 0, chapters.visibleChapter != nil, !chapters.title.isEmpty {
            newTitle = chapters.title
        } else {
            newTitle = episode.title
        }

        if episodeTitleLabel.text != newTitle {
            episodeTitleLabel.text = newTitle
        }

        let newSubtitle = episode.subTitle()
        if subtitleLabel?.text != newSubtitle {
            subtitleLabel?.text = newSubtitle
        }
    }

    @objc private func chapterDidChange() {
        updateTitle()
        if let episode = PlaybackManager.shared.currentEpisode {
            updateArtwork(for: episode)
        }
    }

    @objc private func playbackStarted() {
        if let episode = PlaybackManager.shared.currentEpisode {
            // Forget the auto open marker once a different episode plays, otherwise coming back to a
            // previously auto opened episode never opens the player again. Keeping it for the same
            // episode still stops a reload (e.g. switching to the downloaded file) from re-opening it.
            if lastEpisodeUuidAutoOpened != episode.uuid {
                lastEpisodeUuidAutoOpened = ""
            }

            setupForEpisode(episode)
            showMiniPlayer()
            autoOpenFullScreenPlayerIfNeeded(for: episode)
        } else {
            hideMiniPlayer(true)
        }
    }

    /// Opens the full screen player automatically when the user's setting is on, or when the
    /// current episode is video. For HLS the video isn't known at playback start, so this is also
    /// called when video is detected at runtime (via `videoPlaybackEngineSwitched`).
    private func autoOpenFullScreenPlayerIfNeeded(for episode: BaseEpisode) {
        let shouldOpenAutomatically = UserDefaults.standard.bool(forKey: Constants.UserDefaults.openPlayerAutomatically)
        if shouldOpenAutomatically || PlaybackManager.shared.isCurrentEpisodeVideo, lastEpisodeUuidAutoOpened != episode.uuid {
            lastEpisodeUuidAutoOpened = episode.uuid

            // we called show mini player above, which might have spent time animating itself into view, so give that time to finish
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Animation.defaultAnimationTime) {
                self.openFullScreenPlayer()
            }
        }
    }

    @objc private func videoPlaybackEngineSwitched() {
        // Video can be detected after playback starts (e.g. an HLS stream), so give it the same
        // automatic full screen treatment a video podcast gets.
        guard let episode = PlaybackManager.shared.currentEpisode else { return }
        autoOpenFullScreenPlayerIfNeeded(for: episode)
    }

    @objc private func playbackStarting() {
        playbackStateDidChange()
    }

    @objc private func statusBarHeightDidChange() {
        if !LiquidGlass.isEnabled, miniPlayerShowing() {
            hideMiniPlayer(false)
            showMiniPlayer()
        }
    }

    @objc private func upNextListChanged() {
        playbackStateDidChange()
    }

    @objc private func playbackStateDidChange() {
        guard let episodePlaying = PlaybackManager.shared.currentEpisode else {
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

        let currentTime = PlaybackManager.shared.currentTime
        let duration = PlaybackManager.shared.duration

        var progress: CGFloat = 0
        if currentTime > 0, duration > 0 {
            progress = min(1, CGFloat(currentTime / duration))
        }

        let isIndeterminate = PlaybackManager.shared.isBuffering && PlaybackManager.shared.isPlaying

        playbackProgressView.progress = progress
        playbackProgressView.indeterminant = isIndeterminate

        let amountBuffered = PlaybackManager.shared.futureBufferAvailable
        if amountBuffered > 0 {
            playbackProgressView.bufferedAmount = CGFloat(amountBuffered / (duration - currentTime))
        }

        glassProgressView?.playbackProgress = progress
        glassProgressView?.indeterminate = isIndeterminate

        if amountBuffered > 0 {
            glassProgressView?.bufferedAmount = CGFloat(amountBuffered / (duration - currentTime))
        }

        let remaining = max(0, duration - currentTime - PlaybackManager.shared.deselectedChapterDuration(after: currentTime))

        if isLargeLayoutApplied {
            elapsedLabel?.text = TimeFormatter.shared.playTimeFormat(time: currentTime)
            remainingLabel?.text = remaining > 0 ? TimeFormatter.shared.playTimeFormat(time: remaining) : ""
        }

        if let timeLeftModel {
            let newText = remaining > 0 ? "-" + TimeFormatter.shared.playTimeFormat(time: remaining) : ""
            if timeLeftModel.text != newText {
                let animate = animateNextTimeLeftChange && !UIAccessibility.isReduceMotionEnabled
                animateNextTimeLeftChange = false
                if animate {
                    // Only deliberate skips reach this path, so the
                    // per-second progress ticks stay static; `countsDown`
                    // (set by the skip handlers) picks the roll direction.
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        timeLeftModel.text = newText
                    }
                } else {
                    timeLeftModel.text = newText
                }
            }
        }
    }

    private func updateColors() {
        view.backgroundColor = .clear

        if #available(iOS 26.0, *) {
            updateColorsLiquidGlass()
        } else {
            updateColorsLegacy()
        }

        playPauseBtn.isPlaying = PlaybackManager.shared.isPlaying
    }

    private func updateColorsLegacy() {
        gradientView.colors = [ThemeColor.primaryUi02().withAlphaComponent(0), ThemeColor.primaryUi02()]

        let actionColor = currentPodcastTintColor()
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
        // System color so the vibrancy wrapper can modulate it.
        episodeTitleLabel?.textColor = .label
        timeLeftModel?.color = Color(ThemeColor.primaryText02())

        playPauseBtn.circleColor = .label

        skipBackBtn.tintColor = .label
        skipFwdBtn.tintColor = .label

        glassProgressView?.tintColorOverride = currentPodcastTintColor()
    }

    private func currentPodcastTintColor() -> UIColor {
        if let podcast = podcast(for: PlaybackManager.shared.currentEpisode) {
            return Theme.isDarkTheme ? ColorManager.darkThemeTint(for: podcast) : ColorManager.lightThemeTint(for: podcast)
        } else if let episode = PlaybackManager.shared.currentEpisode as? UserEpisode, episode.imageColor > 0 {
            return AppTheme.userEpisodeColor(number: Int(episode.imageColor))
        } else {
            return AppTheme.userEpisodeColor(number: 1)
        }
    }

    private func podcast(for episode: BaseEpisode?) -> Podcast? {
        if let episode = PlaybackManager.shared.currentEpisode as? Episode {
            return episode.parentPodcast()
        }

        return nil
    }

    @objc private func updateRequired() {
        guard let episode = PlaybackManager.shared.currentEpisode else { return }

        updateColors()
        updateArtwork(for: episode, forceReload: true)
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

/// Backing store for the Liquid Glass mini player's time-left readout.
final class MiniPlayerTimeLeftModel: ObservableObject {
    /// The formatted string shown to the user, e.g. `-12:34`.
    @Published var text: String = ""
    /// Direction the digits roll when `text` changes inside `withAnimation`:
    /// down for skip-forward (less time left), up for skip-back.
    @Published var countsDown: Bool = false
    @Published var color: Color = .primary
}

struct MiniPlayerTimeLeftView: View {
    @ObservedObject var model: MiniPlayerTimeLeftModel

    var body: some View {
        Text(model.text)
            .font(Font.system(size: 10, weight: .regular))
            .monospacedDigit()
            .foregroundColor(model.color)
            .contentTransition(.numericText(countsDown: model.countsDown))
            .lineLimit(1)
    }
}
