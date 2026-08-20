import UIKit
import Combine
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class TranscriptViewController: PlayerItemViewController, AnalyticsSourceProvider {
    let analyticsSource: AnalyticsSource

    private let playbackManager: TranscriptPlaybackManaging
    private var transcript: TranscriptModel?
    private var previousRange: NSRange?

    // Whether a highlight is currently rendered. Tracked separately from
    // `previousRange` because that can be nilled without restyling, leaving a
    // highlight on screen that still needs clearing when we leave matched content.
    private var hasRenderedHighlight = false

    private var canScrollToDismiss = true

    private var isUserScrolling = false
    private var hasNonEmptySelection = false
    // Stays `true` for the entire scroll-back grace period, not just while the
    // user's finger is on the view. `isUserScrolling` flips back to false the
    // instant the drag ends, so without this, the next playback tick would
    // snap the view back to the highlight before the 5s return fires.
    private var isAutoScrollSuppressed = false
    private var autoScrollBackWorkItem: DispatchWorkItem?
    private static let autoScrollBackDelay: TimeInterval = 5.0

    // Position the active cue ~30% from the top of the visible area so a few
    // upcoming lines are always visible below it.
    private static let highlightVerticalAnchor: CGFloat = 0.3

    // `playbackProgress` fires roughly once per second, which means the highlight
    // can land up to ~1s after a cue boundary. Drive updates off the display
    // refresh instead so transitions land within one frame (~16ms at 60Hz).
    // The cue-equality guard inside updateTranscriptPosition makes each tick
    // effectively free when nothing has changed.
    private var highlightDisplayLink: CADisplayLink?

    // Cursor into `transcript.cues` used by `currentCue(at:)` to avoid an O(n)
    // linear scan on every display-link tick. Valid while the active cue is at
    // or ahead of this index; reset when a new transcript is loaded.
    private var cachedCueIndex: Int = 0

    private var isSearching = false
    private var searchIndicesResult: [Int] = []
    private var currentSearchIndex = 0
    private var searchTerm: String?

    private let debounce = Debounce(delay: Constants.defaultDebounceTime)

    private var kmpSearch: KMPSearch?

    private var syncedSeeksCount = 0
    private var appearDate: Date?
    private var autoScrollSuppressedDate: Date?

    private var transcriptManager: TranscriptManager?

    #if DEBUG
    private var debugOverlay: FingerprintDebugOverlay?
    private var debugTimer: Timer?
    #endif

    private var transcriptViewTopConstraint: NSLayoutConstraint?
    private var topGradientTopConstraint: NSLayoutConstraint?
    private var topGradientHeightConstraint: NSLayoutConstraint?
    private var bannerLabelLeadingConstraint: NSLayoutConstraint?
    private var bannerLabelTrailingConstraint: NSLayoutConstraint?

    private var shouldShowPremiumView: Bool {
        return FeatureFlag.generatedTranscripts.enabled &&
        (!SubscriptionHelper.hasActiveSubscription() || !SyncManager.isUserLoggedIn())
    }

    var showGeneratedTranscriptsPremiumOverlay: (() -> Void)?
    var playButtonTapped: ((Bool) -> Void)?

    private var showFromEpisode: Bool {
        analyticsSource == .episode
    }

    init(playbackManager: TranscriptPlaybackManaging, source: AnalyticsSource = .player) {
        self.playbackManager = playbackManager
        self.analyticsSource = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        if FeatureFlag.generatedTranscripts.enabled {
            addGeneratedTranscriptsObservers()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        parent?.view.overrideUserInterfaceStyle = .unspecified
        dismissSearch()
        resetSearch()
        cancelAutoScrollBack()
    }

    deinit {
        autoScrollBackWorkItem?.cancel()
        highlightDisplayLink?.invalidate()
    }

    private func startHighlightDisplayLink() {
        guard FeatureFlag.syncedTranscripts.enabled else { return }
        stopHighlightDisplayLink()
        let link = CADisplayLink(target: self, selector: #selector(highlightTick))
        link.add(to: .main, forMode: .common)
        link.isPaused = !playbackManager.isPlayingEpisode
        highlightDisplayLink = link
        // Opening the transcript while paused leaves the link paused, so
        // `playbackProgress` won't fire and the initial highlight wouldn't
        // appear. Force one position update so the current cue is shown even
        // if playback never resumes.
        updateTranscriptPosition()
    }

    private func stopHighlightDisplayLink() {
        highlightDisplayLink?.invalidate()
        highlightDisplayLink = nil
    }

    /// Toggle the highlight display link based purely on whether playback is
    /// advancing. We deliberately don't gate on `FingerprintTimingManager.state`
    /// here — the existing `guard case .active = ...` inside
    /// `updateTranscriptPosition` already short-circuits the per-tick highlight
    /// work when the manager isn't ready, and stacking a second gate at the
    /// display-link level is what trapped the manager in `.preparing` on the
    /// prior POC-546 attempt (the link would pause before the manager could
    /// post a state change).
    @objc private func updateHighlightDisplayLinkPauseState() {
        highlightDisplayLink?.isPaused = !playbackManager.isPlayingEpisode
    }

    @objc private func highlightTick() {
        updateTranscriptPosition()
    }

    func didDisappear() {
        let syncedState = FingerprintTimingManager.shared.state
        var properties: [String: Sendable] = [
            "synced_state_at_dismiss": syncedState.analyticsName,
            "synced_seeks_count": syncedSeeksCount
        ]
        if let appear = appearDate {
            properties["engagement_seconds"] = Int(Date().timeIntervalSince(appear))
        }
        track(.transcriptDismissed, properties: properties)
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    func setHasGeneratedTranscripts(_ value: Bool) {
        let topMargin = showFromEpisode ? 8.0 : 0.0

        if FeatureFlag.generatedTranscripts.enabled, value {
            transcriptViewTopConstraint?.constant = 80.0 + topMargin
            topGradientTopConstraint?.constant = 100.0 + topMargin
            topGradientHeightConstraint?.constant = 30.0
        } else {
            transcriptViewTopConstraint?.constant = 0.0 + topMargin
            topGradientTopConstraint?.constant = 0.0 + topMargin
            topGradientHeightConstraint?.constant = Sizes.topGradientHeight
        }
        updateTextMargins()
    }

    private func addGeneratedTranscriptsObservers() {
        if shouldShowPremiumView {
            addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(subscriptionStatusDidChange))
        }
        addCustomObserver(Constants.Notifications.episodeTranscriptAvailabilityChanged, selector: #selector(updateGeneratedTranscriptState))
    }

    @objc private func updateGeneratedTranscriptState(_ notification: Notification) {
        guard
            let hasGeneratedTranscripts = notification.userInfo?["hasGeneratedTranscripts"] as? Bool
        else {
            return
        }
        setHasGeneratedTranscripts(hasGeneratedTranscripts)
    }

    private func setupViews() {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitHorizontalSizeClass.self]) { (controller: TranscriptViewController, previousTraitCollection: UITraitCollection) in
            if controller.traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory {
                controller.refreshText()
                controller.refreshError()
                controller.refreshActionButtons()
            }
            controller.updateTextMargins()
        }

        view.addSubview(transcriptView)
        let transcriptViewTopConstraint = transcriptView.topAnchor.constraint(equalTo: view.topAnchor)
        self.transcriptViewTopConstraint = transcriptViewTopConstraint
        NSLayoutConstraint.activate(
            [
                transcriptViewTopConstraint,
                transcriptView.bottomAnchor.constraint(equalTo: showFromEpisode ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor),
                transcriptView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                transcriptView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )

        if FeatureFlag.syncedTranscripts.enabled {
            let tap = UITapGestureRecognizer(target: self, action: #selector(transcriptTapped(_:)))
            transcriptView.addGestureRecognizer(tap)
        }

        updateTextMargins()
        transcriptView.scrollIndicatorInsets = .init(top: 0.75 * Sizes.topGradientHeight, left: 0, bottom: bottomContainerInset, right: 0)

        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate(
            [
                activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -Sizes.activityIndicatorSize / 2),
                activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -Sizes.activityIndicatorSize / 2)
            ]
        )

        view.addSubview(errorView)
        NSLayoutConstraint.activate(
            [
                errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                errorView.widthAnchor.constraint(equalTo: view.readableContentGuide.widthAnchor, constant: -Sizes.textMargin)
            ]
        )

        view.addSubview(topGradient)
        topGradient.translatesAutoresizingMaskIntoConstraints = false
        let topGradientTopConstraint = topGradient.topAnchor.constraint(equalTo: view.topAnchor)
        let topGradientHeightConstraint = topGradient.heightAnchor.constraint(equalToConstant: Sizes.topGradientHeight)
        self.topGradientTopConstraint = topGradientTopConstraint
        self.topGradientHeightConstraint = topGradientHeightConstraint
        NSLayoutConstraint.activate(
            [
                topGradientTopConstraint,
                topGradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                topGradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                topGradientHeightConstraint
            ]
        )

        view.addSubview(bottomGradient)
        bottomGradient.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                bottomGradient.bottomAnchor.constraint(equalTo: showFromEpisode ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor),
                bottomGradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bottomGradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomGradient.heightAnchor.constraint(equalToConstant: Sizes.bottomGradientHeight)
            ]
        )

        view.addSubview(hiddenTextView)

        #if DEBUG
        let overlay = FingerprintDebugOverlay()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            overlay.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            overlay.heightAnchor.constraint(equalToConstant: 16)
        ])
        debugOverlay = overlay
        #endif

        stackView.addArrangedSubview(closeButton)
        stackView.addArrangedSubview(UIView())

        shareButton.isHidden = !FeatureFlag.shareTranscripts.enabled
        stackView.addArrangedSubview(shareButton)

        playButton.isHidden = !showFromEpisode
        stackView.addArrangedSubview(playButton)

        stackView.addArrangedSubview(searchButton)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let topMargin = showFromEpisode ? 8.0 : 0.0
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.widthAnchor.constraint(equalToConstant: 44)
        ])

        if FeatureFlag.generatedTranscripts.enabled {
            view.addSubview(bannerView)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            bannerView.isHidden = true
            NSLayoutConstraint.activate(
                [
                    bannerView.topAnchor.constraint(equalTo: stackView.bottomAnchor),
                    bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    bannerView.heightAnchor.constraint(equalToConstant: Sizes.topGradientHeight)
                ]
            )
        }
    }

    // Only return the searchView as the input acessory view
    // if search has been enabled.
    // This prevents the input acessory view from appearing
    // when selecting text
    override var inputAccessoryView: UIView? {
        isSearching ? searchView : nil
    }

    lazy var searchView: TranscriptSearchAccessoryView = {
        let view = TranscriptSearchAccessoryView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @objc private func displaySearch() {
        isSearching = true
        cancelAutoScrollBack()

        // Keep the inputAccessoryView dark
        parent?.view.overrideUserInterfaceStyle = .dark

        hiddenTextView.becomeFirstResponder()

        // Move focus to the textView on the input accessory view
        searchView.textField.becomeFirstResponder()
        searchView.enableUpDownButtons(false)

        track(.transcriptSearchShown)
    }

    @objc private func playEpisode() {
        playButton.buttonState = playbackManager.isPlayingEpisode ? .play : .pause
        playButtonTapped?(playbackManager.isPlayingEpisode)
    }

    @objc private func shareEpisode() {
        guard let transcript else { return }

        let transcriptText = transcript.attributedText.string
        let activityViewController = UIActivityViewController(activityItems: [transcriptText], applicationActivities: nil)

        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }

        present(activityViewController, animated: true)
        track(.transcriptShared)
    }

    private func dismissSearch() {
        isSearching = false

        searchView.textField.resignFirstResponder()

        resignFirstResponder()
    }

    private lazy var bannerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = L10n.generatedTranscriptsBanner
        label.numberOfLines = 2
        label.font = .font(ofSize: 13, weight: .medium, scalingWith: .footnote, maxSizeCategory: .extraExtraExtraLarge)
        label.textColor = showFromEpisode ? ThemeColor.primaryText01() : .white.withAlphaComponent(0.5)
        label.backgroundColor = .clear
        return label
    }()

    private lazy var bannerView: UIView = {
        let view = UIView()
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = bannerLabel
        view.addSubview(label)

        let stroke = UIView()
        stroke.translatesAutoresizingMaskIntoConstraints = false
        stroke.backgroundColor = showFromEpisode ? ThemeColor.primaryUi05() : .white.withAlphaComponent(0.5)
        view.addSubview(stroke)

        let bannerLabelLeadingConstraint = label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15.0)
        let bannerLabelTrailingConstraint = label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15.0)
        self.bannerLabelLeadingConstraint = bannerLabelLeadingConstraint
        self.bannerLabelTrailingConstraint = bannerLabelTrailingConstraint

        NSLayoutConstraint.activate(
            [
                label.topAnchor.constraint(equalTo: view.topAnchor, constant: 15.0),
                bannerLabelLeadingConstraint,
                bannerLabelTrailingConstraint,
                stroke.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 15.0),
                stroke.leadingAnchor.constraint(equalTo: label.leadingAnchor),
                stroke.widthAnchor.constraint(equalToConstant: 48),
                stroke.heightAnchor.constraint(equalToConstant: 1)
            ]
        )
        return view
    }()

    private lazy var transcriptView: UITextView = {
        let textView = UITextView(usingTextLayoutManager: false)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.showsVerticalScrollIndicator = true
        textView.inputAccessoryView = nil
        return textView
    }()

    private lazy var activityIndicatorView: AngularActivityIndicator = {
        let activityIndicatorView = AngularActivityIndicator(size: CGSize(width: Sizes.activityIndicatorSize, height: Sizes.activityIndicatorSize), lineWidth: 2.0, duration: 1.0)
        activityIndicatorView.color = ThemeColor.playerContrast02()
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicatorView
    }()

    private lazy var errorView: TranscriptErrorView = {
        let source: TranscriptErrorView.ViewSource = analyticsSource == .episode ? .episode : .player
        return TranscriptErrorView(source: source) { [weak self] in
            self?.retryLoad()
        }
    }()

    private lazy var closeButton: TintableImageButton! = {
        let closeButton = TintableImageButton()
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.tintColor = showFromEpisode ? ThemeColor.primaryInteractive01() : ThemeColor.primaryIcon02()
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return closeButton
    }()

    private lazy var searchButton: RoundButton = {
        let titleColor = showFromEpisode ? ThemeColor.primaryInteractive01() : .white
        let tintColor = showFromEpisode ? ThemeColor.primaryInteractive01().withAlphaComponent(0.1) : .white.withAlphaComponent(0.2)

        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(top: 4, leading: 12, bottom: 4, trailing: 12)
        configuration.baseForegroundColor = titleColor
        configuration.baseBackgroundColor = tintColor

        let searchButton = RoundButton(type: .system)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(with: .callout, maxSizeCategory: .extraExtraExtraLarge)
        ]
        searchButton.setAttributedTitle(NSAttributedString(string: L10n.search, attributes: attributes), for: .normal)
        searchButton.addTarget(self, action: #selector(displaySearch), for: .touchUpInside)
        searchButton.setTitleColor(titleColor, for: .normal)
        searchButton.tintColor = tintColor
        searchButton.layer.masksToBounds = true
        searchButton.configuration = configuration
        searchButton.titleLabel?.adjustsFontForContentSizeCategory = false
        return searchButton
    }()

    private lazy var playButton: RoundPlayPauseButton = {
        let playButton = RoundPlayPauseButton.makeButton(playbackManager: playbackManager)
        playButton.addTarget(self, action: #selector(playEpisode), for: .touchUpInside)
        playButton.titleLabel?.adjustsFontForContentSizeCategory = false
        return playButton
    }()

    private lazy var shareButton: RoundButton = {
        let titleColor = showFromEpisode ? ThemeColor.primaryInteractive01() : .white
        let tintColor = showFromEpisode ? ThemeColor.primaryInteractive01().withAlphaComponent(0.1) : .white.withAlphaComponent(0.2)

        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(top: 4, leading: 12, bottom: 4, trailing: 12)
        configuration.baseForegroundColor = titleColor
        configuration.baseBackgroundColor = tintColor

        let shareButton = RoundButton(type: .system)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(with: .callout, maxSizeCategory: .extraExtraExtraLarge)
        ]
        shareButton.setAttributedTitle(NSAttributedString(string: L10n.share, attributes: attributes), for: .normal)
        shareButton.addTarget(self, action: #selector(shareEpisode), for: .touchUpInside)
        shareButton.setTitleColor(titleColor, for: .normal)
        shareButton.tintColor = tintColor
        shareButton.layer.masksToBounds = true
        shareButton.configuration = configuration
        shareButton.titleLabel?.adjustsFontForContentSizeCategory = false
        return shareButton
    }()

    private lazy var hiddenTextView: UITextField = {
        let textView = UITextField()
        textView.layer.opacity = 0
        return textView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private lazy var topGradient: GradientView = {
        GradientView(firstColor: Colors.gradientColor, secondColor: Colors.gradientColor.withAlphaComponent(0))
    }()

    private lazy var bottomGradient: GradientView = {
        GradientView(firstColor: Colors.gradientColor.withAlphaComponent(0), secondColor: Colors.gradientColor)
    }()

    var bottomContainerInset: CGFloat {
        0.7 * Sizes.bottomGradientHeight
    }

    override func willBeAddedToPlayer() {
        updateColors()
        loadTranscript()
        addObservers()
        transcriptView.delegate = self
#if DEBUG
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.debugOverlay?.update()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        debugTimer = timer
#endif
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()
        stopHighlightDisplayLink()
        if FeatureFlag.syncedTranscripts.enabled {
            FingerprintTimingManager.shared.stop()
        }
#if DEBUG
        debugTimer?.invalidate()
        debugTimer = nil
#endif
    }

    private func stopSyncedTranscripts() {
        FingerprintTimingManager.shared.stop()
        stopHighlightDisplayLink()
    }

    override func themeDidChange() {
        updateColors()
    }

    private func updateColors() {
        let primaryColor =  showFromEpisode ? ThemeColor.primaryUi01() : PlayerColorHelper.playerBackgroundColor01()
        let secondaryColor =  showFromEpisode ? ThemeColor.primaryText01() : ThemeColor.playerContrast02()
        let activityIndicatorViewColor: UIColor = showFromEpisode ? ThemeColor.primaryIcon02() : ThemeColor.playerContrast02()
        let activityIndicatorViewStyle: UIScrollView.IndicatorStyle = showFromEpisode ? (Theme.sharedTheme.activeTheme.isDark ? .white : .black) : .white

        view.backgroundColor = primaryColor
        transcriptView.backgroundColor =  primaryColor
        transcriptView.textColor = secondaryColor
        transcriptView.indicatorStyle = activityIndicatorViewStyle
        activityIndicatorView.color = activityIndicatorViewColor
        updateGradientColors()
        if FeatureFlag.generatedTranscripts.enabled {
            bannerView.backgroundColor = primaryColor
        }
    }

    private func updateGradientColors() {
        let gradientColor = showFromEpisode ? ThemeColor.primaryUi01() : Colors.gradientColor
        topGradient.updateColors(firstColor: gradientColor, secondColor: gradientColor.withAlphaComponent(0))
        bottomGradient.updateColors(firstColor: gradientColor.withAlphaComponent(0), secondColor: gradientColor)
    }

    @objc private func update() {
        updateColors()
        resetKmp()
        resetSearch()
        loadTranscript()
    }

    @objc private func closeTapped() {
        containerDelegate?.dismissTranscript()
    }

    private func setupLoadingState() {
        transcriptView.isHidden = true
        restoreControlButtonsLayout()
        setControlButtonsVisible(false)
        errorView.isHidden = true
        activityIndicatorView.startAnimating()
    }

    private func setupShowTranscriptState() {
        transcriptView.isHidden = false
        setControlButtonsVisible(true)
        errorView.isHidden = true
        activityIndicatorView.stopAnimating()
    }

    private func setControlButtonsVisible(_ visible: Bool) {
        let buttons: [UIButton] = [searchButton, shareButton, playButton]
        buttons.forEach { setControlButton($0, visible: visible) }
    }

    private func setControlButton(_ button: UIButton, visible: Bool) {
        guard !button.isHidden else { return }
        button.alpha = visible ? 1 : 0
        button.isUserInteractionEnabled = visible
    }

    private func restoreControlButtonsLayout() {
        shareButton.isHidden = !FeatureFlag.shareTranscripts.enabled
        searchButton.isHidden = false
    }

    private var currentEpisodeUUID: String?

    private func loadTranscript() {
        guard let episodeUUID = playbackManager.episodeUUID, let podcastUUID = playbackManager.podcastUUID else {
            return
        }

        let shouldResetPosition = currentEpisodeUUID != episodeUUID
        currentEpisodeUUID = episodeUUID

        transcriptManager = TranscriptManager(episodeUUID: episodeUUID, podcastUUID: podcastUUID)

        setupLoadingState()

        Task.detached { [weak self, transcriptManager] in
            guard let self, let transcriptManager else {
                return
            }

            do {
                let transcript = try await transcriptManager.loadTranscript()
                let hasGeneratedTranscripts = FeatureFlag.generatedTranscripts.enabled && transcriptManager.hasGeneratedTranscripts
                let isDisplayingGenerated = transcriptManager.isDisplayingGeneratedTranscript
                await MainActor.run {
                    self.setHasGeneratedTranscripts(hasGeneratedTranscripts)
                    if isDisplayingGenerated {
                        let isCurrentEpisode = PlaybackManager.shared.isCurrentEpisode(uuid: episodeUUID)
                        if FeatureFlag.syncedTranscripts.enabled, !self.showFromEpisode || isCurrentEpisode {
                            FingerprintTimingManager.shared.prepareForCurrentEpisode()
                        }
                        self.startHighlightDisplayLink()
                    } else {
                        self.stopSyncedTranscripts()
                    }
                    UIView.animate(withDuration: 0.25) {
                        if hasGeneratedTranscripts, self.shouldShowPremiumView {
                            self.stackView.alpha = 0
                            self.showGeneratedTranscriptsPremiumOverlay?()
                        } else {
                            self.appearDate = Date()
                            let syncedState = FingerprintTimingManager.shared.state
                            self.track(.transcriptShown, properties: [
                                "type": transcript.type,
                                "show_as_webpage": transcript.hasJavascript,
                                "synced_flag_enabled": FeatureFlag.syncedTranscripts.enabled,
                                "synced_state": syncedState.analyticsName
                            ])
                        }
                        self.bannerView.isHidden = !hasGeneratedTranscripts
                    }
                }
                await show(transcript: transcript, resetPosition: shouldResetPosition)
            } catch {
                await stopSyncedTranscripts()
                await track(.transcriptError, properties: ["error_code": (error as NSError).code])
                await show(error: error)
            }
        }
    }

    @objc private func showUpsellView() {
        NavigationManager.sharedManager.showUpsellView(from: self, source: .generatedTranscripts)
    }

    @objc private func subscriptionStatusDidChange() {
        if shouldShowPremiumView {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if FeatureFlag.generatedTranscripts.enabled,
               transcriptManager?.hasGeneratedTranscripts == true {
                self.stackView.alpha = 1.0
            }
        }
    }

    private func retryLoad() {
        errorView.isHidden = true
        loadTranscript()
    }

    private func resetSearch() {
        searchIndicesResult = []
        currentSearchIndex = 0
        searchView.textField.text = ""
        searchTerm = nil
        updateNumberOfResults()
        refreshText()
    }

    private func resetKmp() {
        kmpSearch = nil
    }

    private func refreshActionButtons() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(with: .callout, maxSizeCategory: .extraExtraExtraLarge)
        ]
        searchButton.setAttributedTitle(NSAttributedString(string: L10n.search, attributes: attributes), for: .normal)
        shareButton.setAttributedTitle(NSAttributedString(string: L10n.share, attributes: attributes), for: .normal)
        playButton.updateSize()

        bannerLabel.font = .font(ofSize: 13, weight: .medium, scalingWith: .footnote, maxSizeCategory: .extraExtraExtraLarge)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTextMargins()
    }

    private func updateTextMargins() {
        let margin = self.view.readableContentGuide.layoutFrame.minX + Sizes.textMargin
        var topInset = 0.75 * Sizes.topGradientHeight
        if FeatureFlag.generatedTranscripts.enabled,
           transcriptManager?.hasGeneratedTranscripts == true {
            let newMargin = margin + 5.0
            bannerLabelLeadingConstraint?.constant = newMargin
            bannerLabelTrailingConstraint?.constant = -newMargin
            topInset += 5.0
        }
        transcriptView.textContainerInset = .init(top: topInset, left: margin, bottom: bottomContainerInset, right: margin)
    }

    @MainActor
    private func refreshError() {
        errorView.setTextAttributes(makeStyle(alignment: .center))
    }

    @MainActor
    private func refreshText() {
        guard let transcript else {
            return
        }
        transcriptView.attributedText = styleText(transcript: transcript)
    }

    private func show(transcript: TranscriptModel, resetPosition: Bool) {
        setupShowTranscriptState()
        previousRange = nil
        cachedCueIndex = 0
        hasRenderedHighlight = false
        self.transcript = transcript
        hasNonEmptySelection = false
        transcriptView.attributedText = styleText(transcript: transcript)
        if resetPosition {
            transcriptView.setContentOffset(.zero, animated: false)
        }
    }

    private func makeStyle(alignment: NSTextAlignment = .natural) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = alignment

        var standardFont = UIFont.preferredFont(forTextStyle: .body)

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(
          withTextStyle: .body)
          .withDesign(.serif) {
            standardFont =  UIFont(descriptor: descriptor, size: 0)
        }

        let normalStyle: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: standardFont,
            .foregroundColor: showFromEpisode ? ThemeColor.primaryText01() : ThemeColor.playerContrast02()
        ]

        return normalStyle
    }

    private func styleText(transcript: TranscriptModel, position: Double = -1) -> NSAttributedString {
        let formattedText = NSMutableAttributedString(attributedString: transcript.attributedText)
        formattedText.beginEditing()
        let normalStyle = makeStyle()
        var highlightStyle = normalStyle
        highlightStyle[.foregroundColor] = showFromEpisode ? ThemeColor.primaryInteractive01() : ThemeColor.playerContrast01()

        let fullLength = NSRange(location: 0, length: formattedText.length)
        formattedText.addAttributes(normalStyle, range: fullLength)

        if position != -1, let range = transcript.firstCue(containing: position)?.characterRange {
            formattedText.addAttributes(highlightStyle, range: range)
        }

        let speakerFont = UIFont.font(ofSize: 12, scalingWith: .footnote)
        formattedText.enumerateAttribute(.transcriptSpeaker, in: fullLength, options: [.reverse, .longestEffectiveRangeNotRequired]) { value, range, _ in
            if value == nil {
                return
            }
            formattedText.addAttribute(.font, value: speakerFont, range: range)
        }

        if let searchTerm {
            let length = formattedText.length
            let searchTermLength = searchTerm.count
            searchIndicesResult.enumerated().forEach { index, indice in
                if indice + searchTermLength <= length {
                    let backgroundColor = showFromEpisode ? ThemeColor.primaryText01().withAlphaComponent(index == currentSearchIndex ? 1 : 0.6) : .white.withAlphaComponent(index == currentSearchIndex ? 1 : 0.4)
                    let highlightStyle: [NSAttributedString.Key: Any] = [
                        .backgroundColor: backgroundColor,
                        .foregroundColor: showFromEpisode ? ThemeColor.primaryUi01() : index == currentSearchIndex ? UIColor.black : ThemeColor.playerContrast01()
                    ]

                    formattedText.addAttributes(highlightStyle, range: NSRange(location: indice, length: searchTermLength))
                }
            }
        }
        formattedText.endEditing()
        return formattedText
    }

    private func show(error: Error) {
        activityIndicatorView.stopAnimating()
        // Collapse the transcript-only controls so the play button sits at the trailing edge.
        shareButton.isHidden = true
        searchButton.isHidden = true
        setControlButton(playButton, visible: true)
        var message = L10n.transcriptErrorFailedToLoad
        if let transcriptError = error as? TranscriptError {
            message = transcriptError.localizedDescription
        }
        errorView.isHidden = false
        errorView.setMessage(message, attributes: makeStyle(alignment: .center))
    }

    private func addObservers() {
        if !showFromEpisode {
            addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(update))
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        if FeatureFlag.syncedTranscripts.enabled {
            addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(updateTranscriptPosition))
            addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(updateHighlightDisplayLinkPauseState))
            addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(updateHighlightDisplayLinkPauseState))
            addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(updateHighlightDisplayLinkPauseState))
        }
    }

    @objc private func updateTranscriptPosition() {
        guard let transcript else { return }

        let rawTime = playbackManager.currentTime()

        // Highlighting is opt-in: only paint while playback is confidently on
        // matched content. Off it — dynamic ads, unmatched audio, regions not yet
        // fingerprinted, or before/after the mapped range — we clear and leave it
        // cleared. Crossing the last matched anchor flips this immediately, so we
        // never highlight ad words first and retract them.
        guard case .active = FingerprintTimingManager.shared.state,
              let position = FingerprintTimingManager.shared.matchedReferenceTime(forPlaybackTime: rawTime) else {
            clearHighlight(transcript: transcript)
            return
        }

        let currentCue = currentCue(at: position, in: transcript.cues)

        if let cue = currentCue, cue.characterRange != previousRange {
            let range = cue.characterRange
            previousRange = range
            hasRenderedHighlight = true
            transcriptView.attributedText = styleText(transcript: transcript, position: position)
            if !isUserScrolling, !isSearching, !isAutoScrollSuppressed {
                transcriptView.scrollToRange(range, verticalAnchor: Self.highlightVerticalAnchor)
            }
            #if DEBUG
            let intoCue = position - cue.startTime
            FileLog.shared.addMessage(
                "[transcript-offset] playback=\(String(format: "%.3f", rawTime))" +
                " reference=\(String(format: "%.3f", position))" +
                " cue=[\(String(format: "%.3f", cue.startTime))..\(String(format: "%.3f", cue.endTime))]" +
                " intoCue=\(String(format: "%+.3f", intoCue))"
            )
            #endif
        } else if let startTime = transcript.cues.first?.startTime, position < startTime {
            // Before the first cue there's nothing to highlight — clear any rendered
            // highlight rather than just nil'ing `previousRange`, which would leave a
            // painted range on screen.
            clearHighlight(transcript: transcript)
            if !isUserScrolling, !isSearching, !isAutoScrollSuppressed {
                transcriptView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            }
        }
    }

    /// Remove any rendered highlight while leaving the scroll position untouched.
    /// Mutates `textStorage` in place rather than reassigning `attributedText`
    /// (which resets the text view's scroll on the next layout pass), and keys off
    /// `hasRenderedHighlight` rather than `previousRange` since the latter can be
    /// nilled elsewhere without restyling, leaving a highlight on screen.
    private func clearHighlight(transcript: TranscriptModel) {
        guard hasRenderedHighlight else { return }
        previousRange = nil
        hasRenderedHighlight = false
        transcriptView.textStorage.setAttributedString(styleText(transcript: transcript))
    }

    // Resolves the cue containing `position` in O(1) amortized for normal
    // forward playback by starting from `cachedCueIndex` rather than scanning
    // from the beginning on every display-link tick. Falls back to a full
    // scan only on backward seeks.
    private func currentCue(at position: Double, in cues: [TranscriptCue]) -> TranscriptCue? {
        guard !cues.isEmpty else { return nil }
        let cached = min(cachedCueIndex, cues.count - 1)

        if cues[cached].contains(timeInSeconds: position) {
            return cues[cached]
        }

        // Backward seek — match the original `first { contains }` semantics
        // so overlapping cues resolve to the earliest match.
        if position < cues[cached].startTime {
            if let idx = cues.firstIndex(where: { $0.contains(timeInSeconds: position) }) {
                cachedCueIndex = idx
                return cues[idx]
            }
            return nil
        }

        var i = cached + 1
        while i < cues.count, cues[i].startTime <= position {
            if cues[i].contains(timeInSeconds: position) {
                cachedCueIndex = i
                return cues[i]
            }
            i += 1
        }
        return nil
    }

    // MARK: - Auto-scroll back to highlight

    private func scheduleAutoScrollBack() {
        cancelAutoScrollBack()
        guard FeatureFlag.syncedTranscripts.enabled else { return }
        guard !isSearching else { return }
        isAutoScrollSuppressed = true
        autoScrollSuppressedDate = Date()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isAutoScrollSuppressed = false
            self.autoScrollBackWorkItem = nil
            self.scrollBackToCurrentHighlight()
        }
        autoScrollBackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.autoScrollBackDelay, execute: workItem)
    }

    private func cancelAutoScrollBack() {
        autoScrollBackWorkItem?.cancel()
        autoScrollBackWorkItem = nil
        isAutoScrollSuppressed = false
    }

    private func scrollBackToCurrentHighlight() {
        // Only catch up to the highlight if audio is moving. When paused, the
        // highlight is static and yanking the view back to it would fight the
        // user who deliberately scrolled elsewhere to read.
        guard !isSearching, !isUserScrolling, playbackManager.isPlayingEpisode, let previousRange else { return }
        transcriptView.scrollToRange(previousRange, verticalAnchor: Self.highlightVerticalAnchor)
        var properties: [String: Sendable] = [:]
        if let suppressedDate = autoScrollSuppressedDate {
            properties["manual_scroll_duration_ms"] = Int(Date().timeIntervalSince(suppressedDate) * 1000)
        }
        track(.syncedTranscriptsAutoScrollResumed, properties: properties)
    }

    @objc private func transcriptTapped(_ gesture: UITapGestureRecognizer) {
        // Gate on `canSeek` rather than `isPlayingEpisode` so taps still seek
        // while audio is paused, but stay inert in the Episode Detail flow
        // where the playback manager's `seekTo` is a no-op (avoids firing
        // analytics or showing toasts for a seek that can't happen).
        guard let transcript, playbackManager.canSeek else { return }
        // Tap-to-seek relies on fingerprint timing that only exists for
        // Pocket Casts-generated transcripts. Bail out for external ones so
        // we don't surface the "download to seek" hint that doesn't apply.
        guard transcriptManager?.isDisplayingGeneratedTranscript == true else { return }

        let location = gesture.location(in: transcriptView)
        let layoutManager = transcriptView.layoutManager
        let textContainer = transcriptView.textContainer
        let offset = CGPoint(
            x: location.x - transcriptView.textContainerInset.left,
            y: location.y - transcriptView.textContainerInset.top
        )
        let charIndex = layoutManager.characterIndex(
            for: offset,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        guard let cue = transcript.cues.first(where: { NSLocationInRange(charIndex, $0.characterRange) }) else { return }

        let referenceTime = cue.startTime

        guard let seekTime = FingerprintTimingManager.shared.playbackTime(forReferenceTime: referenceTime) else {
            let syncedState = FingerprintTimingManager.shared.state
            track(.syncedTranscriptsSeekFailed, properties: [
                "reason": "mapping_unavailable",
                "synced_state": syncedState.analyticsName
            ])
            if case .unavailable = syncedState { return }
            let status = playbackManager.episodeUUID
                .flatMap { DataManager.sharedManager.findBaseEpisode(uuid: $0) }
                .flatMap { DownloadStatus(rawValue: $0.episodeStatus) }
            if status == .downloaded || status == .downloadedForStreaming { return }
            Toast.show(L10n.transcriptTapToSeekStreamingUnavailable)
            return
        }

        let fromPosition = playbackManager.currentTime()
        playbackManager.seekTo(time: seekTime)
        syncedSeeksCount += 1
        track(.syncedTranscriptsSeekUsed, properties: [
            "from_position_seconds": Int(fromPosition),
            "to_position_seconds": Int(seekTime)
        ])
    }

    // MARK: - Search

    func performSearch(_ term: String) {
        Task {
            findOccurrences(of: term)
            updateNumberOfResults()
            refreshText()
            scrollToFirstResult()
        }
    }

    func findOccurrences(of term: String) {
        guard let transcriptText = transcript?.attributedText.string,
              !term.isEmpty else {
            resetSearch()
            return
        }

        if kmpSearch == nil {
            kmpSearch = KMPSearch(text: transcriptText)
        }
        searchIndicesResult = kmpSearch?.search(for: term) ?? []
        currentSearchIndex = 0
        searchTerm = term
    }

    @MainActor
    func updateNumberOfResults() {
        if searchTerm == nil {
            searchView.updateLabel("")
            searchView.enableUpDownButtons(false)
            return
        }

        if searchIndicesResult.isEmpty {
            searchView.updateLabel("0")
            searchView.enableUpDownButtons(false)
            return
        }

        searchView.enableUpDownButtons(true)
        searchView.updateLabel(L10n.searchResults(currentSearchIndex + 1, searchIndicesResult.count))
    }

    func scrollToFirstResult() {
        guard let searchTerm,
              let firstResultRange = searchIndicesResult.first.map({ NSRange(location: $0, length: searchTerm.count)}) else {
            return
        }
        transcriptView.scrollToRange(firstResultRange)
    }

    // MARK: - Keyboard

    @objc func keyboardWillShow(_ notification: Notification) {
        adjustTextViewForKeyboard(notification: notification, show: true)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        adjustTextViewForKeyboard(notification: notification, show: false)
    }

    func adjustTextViewForKeyboard(notification: Notification, show: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        let adjustmentHeight = (show ? keyboardHeight - (view.distanceFromBottom() ?? 0) : 0)
        let previousContentOffset = transcriptView.contentOffset
        UIView.animate(withDuration: animationDuration, animations: { [weak self] in
            guard let self else { return }

            if isSearching {
                transcriptView.setContentOffset(previousContentOffset, animated: false)
            }

            transcriptView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: adjustmentHeight, right: 0)
            transcriptView.verticalScrollIndicatorInsets.bottom = show ? adjustmentHeight : bottomContainerInset
        }, completion: { [weak self] _ in
            guard let self else { return }

            if isSearching {
                transcriptView.setContentOffset(previousContentOffset, animated: false)
            }
        })
    }

    // MARK: - Tracks

    func track(_ event: AnalyticsEvent, properties: [String: Sendable] = [:]) {
        var properties = properties

        if let episodeUUID = playbackManager.episodeUUID,
           let parentIdentifier = playbackManager.parentIdentifier {
            properties["episode_uuid"] = episodeUUID
            properties["podcast_uuid"] = parentIdentifier
        }

        properties["source"] = analyticsSource.rawValue

        Analytics.track(event, properties: properties)
    }

    // MARK: - Constants

    private enum Sizes {
        static let topGradientHeight: CGFloat = 60
        static let bottomGradientHeight: CGFloat = 60
        static let activityIndicatorSize: CGFloat = 30
        static let textMargin: CGFloat = 8
    }

    private enum Colors {
        static var gradientColor: UIColor {
            PlayerColorHelper.playerBackgroundColor01()
        }
    }
}

extension TranscriptViewController: UIScrollViewDelegate {

    // Only allow scroll to dismiss if scrolling bottom from the top
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if canScrollToDismiss {
            scrollViewHandler?.scrollViewDidScroll?(scrollView)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        canScrollToDismiss = scrollView.contentOffset.y == 0
        isUserScrolling = true
        cancelAutoScrollBack()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            userScrollDidEnd()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        userScrollDidEnd()
    }

    private func userScrollDidEnd() {
        isUserScrolling = false
        scheduleAutoScrollBack()
    }
}

extension TranscriptViewController: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        let wasEmpty = !hasNonEmptySelection
        let isNonEmpty = textView.selectedRange.length > 0
        hasNonEmptySelection = isNonEmpty
        if wasEmpty && isNonEmpty {
            track(.transcriptTextHighlighted)
        }
    }

    func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        guard let bookmarkAction = makeBookmarkAction(for: range) else { return nil }

        // Leads the menu: bookmarking is what the transcript is selected for, and the system
        // actions run several pages deep on a phone
        return UIMenu(children: [bookmarkAction] + suggestedActions)
    }
}

// MARK: - Bookmarking a selection

private extension TranscriptViewController {
    /// Where a selected passage sits on the audio, and on the transcript's own timeline when
    /// there is one worth recording.
    struct BookmarkPosition {
        /// The playback time the bookmark is created at
        let time: TimeInterval

        /// The same moment on the transcript's reference timeline, for a generated transcript;
        /// nil for an external one, which is cued against the audio itself
        let referenceTime: TimeInterval?
    }

    /// The "Bookmark" action to offer alongside the selection's system actions, or nil when
    /// this selection can't be bookmarked.
    func makeBookmarkAction(for range: NSRange) -> UIAction? {
        guard range.length > 0, PaidFeature.bookmarks.isUnlocked,
              let transcript,
              let episode = playbackManager.episodeUUID.flatMap({ DataManager.sharedManager.findBaseEpisode(uuid: $0) }),
              let position = bookmarkPosition(forSelectionStartingAt: range.location, in: transcript) else {
            return nil
        }

        return UIAction(title: L10n.transcriptBookmarkSelection, image: UIImage(systemName: "bookmark")) { [weak self] _ in
            self?.addBookmark(at: position, for: episode, selection: range, in: transcript)
        }
    }

    /// The moment the selection starts at, which is where the cue holding its first character begins.
    func bookmarkPosition(forSelectionStartingAt characterIndex: Int, in transcript: TranscriptModel) -> BookmarkPosition? {
        guard let cue = transcript.cue(atCharacterIndex: characterIndex) else { return nil }

        // An external transcript is cued against the audio, so its times are playback times
        // already. A generated one is cued against a reference copy of the episode that
        // dynamic ads shift away from, so the cue has to be mapped back onto this device's
        // audio — and where it can't be, there's no time to bookmark.
        guard transcriptManager?.isDisplayingGeneratedTranscript == true else {
            return BookmarkPosition(time: cue.startTime, referenceTime: nil)
        }

        return FingerprintTimingManager.shared.playbackTime(forReferenceTime: cue.startTime).map {
            BookmarkPosition(time: $0, referenceTime: cue.startTime)
        }
    }

    func addBookmark(at position: BookmarkPosition, for episode: BaseEpisode, selection: NSRange, in transcript: TranscriptModel) {
        let manager = PlaybackManager.shared.bookmarkManager

        // The passage is only read by the Smart Bookmarks path, so it's stored on the same terms
        let selectedText = BookmarkManager.isTitleSuggestionEnabled
            ? BookmarkTranscriptSnippetExtractor.text(in: selection, of: transcript.attributedText)
            : ""
        let passage = selectedText.isEmpty ? nil : BookmarkUpdateParameters.Passage(text: selectedText, location: selection.location)

        // Asked before adding, because `add` hands back the bookmark that's already there when
        // this moment has one — the sheet then edits that one instead of titling a new one
        let isNew = manager.dataManager.existingBookmark(forEpisode: episode.uuid, time: position.time) == nil

        guard let bookmark = manager.add(to: episode,
                                         at: position.time,
                                         passage: passage,
                                         referenceTime: position.referenceTime,
                                         source: .transcript) else { return }

        // Dropping the selection takes the menu with it, so the transcript is readable again
        // behind the edit sheet
        transcriptView.selectedRange = NSRange(location: selection.location, length: 0)

        Analytics.track(.bookmarkCreated, source: BookmarkAnalyticsSource.transcript, properties: [
            "episode_uuid": episode.uuid,
            "podcast_uuid": (episode as? Episode)?.podcastUuid ?? "user_file",
            "time": Int(position.time)
        ])

        showBookmarkEdit(bookmark, isNew: isNew, manager: manager)
    }

    /// The transcript titles its own bookmarks rather than leaving it to the player's bookmarks
    /// tab, which can't present over a transcript opened from Episode Details and isn't there at
    /// all until the full screen player has been opened.
    func showBookmarkEdit(_ bookmark: Bookmark, isNew: Bool, manager: BookmarkManager) {
        let controller = BookmarkEditTitleViewController(manager: manager,
                                                        bookmark: bookmark,
                                                        state: isNew ? .adding : .updating,
                                                        style: showFromEpisode ? .themed : .player,
                                                        source: .transcript) { [weak self] outcome in
            self?.handleBookmarkEditDismissed(bookmark, isNew: isNew, manager: manager, outcome: outcome)
        }

        present(controller, animated: true)
    }

    func handleBookmarkEditDismissed(_ bookmark: Bookmark, isNew: Bool, manager: BookmarkManager, outcome: BookmarkEditOutcome) {
        // Only a bookmark this selection just made is the sheet's to take back
        guard isNew else { return }

        switch outcome {
        case .cancelled:
            Task { await manager.remove([bookmark]) }

        case .saved(let title):
            let message = title == L10n.bookmarkDefaultTitle ? L10n.bookmarkAdded : L10n.bookmarkAddedNotification(title)

            // Only the player has a bookmarks tab to send them to
            let actions: [Toast.Action]? = showFromEpisode ? nil : [
                .init(title: L10n.bookmarkAddedButtonTitle) { [weak self] in
                    self?.containerDelegate?.dismissTranscript()
                    self?.containerDelegate?.scrollToBookmarks()
                }
            ]

            Toast.show(message, actions: actions, theme: .playerTheme)
        }
    }
}

extension TranscriptViewController: TranscriptSearchAccessoryViewDelegate {
    func doneTapped() {
        dismissSearch()
        resetSearch()
        searchView.removeFromSuperview()
        scheduleAutoScrollBack()
    }

    func searchButtonTapped() {
        becomeFirstResponder()
    }

    func search(_ term: String) {
        if term.isEmpty {
            debounce.cancel()
            resetSearch()
            return
        }

        debounce.call { [weak self] in
            self?.performSearch(term)
        }
    }

    func previousMatch() {
        track(.transcriptSearchPreviousResult)
        updateCurrentSearchIndex(decrement: true)
        processMatch()
    }

    func nextMatch() {
        track(.transcriptSearchNextResult)
        updateCurrentSearchIndex(decrement: false)
        processMatch()
    }

    private func updateCurrentSearchIndex(decrement: Bool) {
        if decrement {
            currentSearchIndex = (currentSearchIndex - 1 < 0) ? searchIndicesResult.count - 1 : currentSearchIndex - 1
        } else {
            currentSearchIndex = (currentSearchIndex + 1 >= searchIndicesResult.count) ? 0 : currentSearchIndex + 1
        }
    }

    private func processMatch() {
        if searchIndicesResult.isEmpty {
            return
        }

        updateNumberOfResults()
        refreshText()
        transcriptView.scrollToRange(.init(location: searchIndicesResult[currentSearchIndex], length: searchTerm?.count ?? 0))
    }
}

class RoundButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
    }
}

fileprivate class RoundPlayPauseButton: RoundButton {
    private var cancellables = Set<AnyCancellable>()
    private var playbackManager: TranscriptPlaybackManaging?

    enum ButtonState {
        case play
        case pause

        var imageName: String {
            switch self {
            case .play:
                return "play.fill"
            case .pause:
                return "pause.fill"
            }
        }

        var buttonTitle: String {
            switch self {
            case .play:
                return L10n.play
            case .pause:
                return L10n.pause
            }
        }
    }

    var buttonState: ButtonState = .play {
        didSet {
            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            let image = UIImage(systemName: buttonState.imageName, withConfiguration: config)?
                .withRenderingMode(.alwaysTemplate)
            let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.font(with: .callout, maxSizeCategory: .extraExtraExtraLarge)
            ]
            setAttributedTitle(NSAttributedString(string: buttonState.buttonTitle, attributes: attributes), for: .normal)
            setImage(image, for: .normal)
        }
    }

    func updateSize() {
        let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.font(with: .callout, maxSizeCategory: .extraExtraExtraLarge)
        ]
        setAttributedTitle(NSAttributedString(string: buttonState.buttonTitle, attributes: attributes), for: .normal)
    }

    static func makeButton(playbackManager: TranscriptPlaybackManaging) -> RoundPlayPauseButton {
        let titleColor = ThemeColor.primaryInteractive01()
        let tintColor = ThemeColor.primaryInteractive01().withAlphaComponent(0.1)

        var  bg = UIBackgroundConfiguration.clear()
        bg.backgroundColor = tintColor
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(top: 4, leading: 12, bottom: 4, trailing: 12)
        configuration.imagePadding = 8.0
        configuration.background = bg
        configuration.baseForegroundColor = ThemeColor.primaryInteractive01()

        let playButton = RoundPlayPauseButton(type: .system)
        playButton.playbackManager = playbackManager
        playButton.buttonState = playbackManager.isPlayingEpisode ? .pause : .play
        playButton.setupObservers()
        playButton.setTitleColor(titleColor, for: .normal)
        playButton.tintColor = tintColor
        playButton.layer.masksToBounds = true
        playButton.configuration = configuration
        return playButton
    }

    func setupObservers() {
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackStarted),
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackPaused),
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackEnded)
        )
        .receive(on: RunLoop.main)
        .sink { [unowned self] _ in
            self.updatePlayingState()
        }
        .store(in: &cancellables)
    }

    private func updatePlayingState() {
        buttonState = playbackManager?.isPlayingEpisode == true ? .pause : .play
    }
}
