import UIKit
import Combine
import PocketCastsServer
import PocketCastsUtils

class TranscriptViewController: PlayerItemViewController, AnalyticsSourceProvider {
    let analyticsSource: AnalyticsSource

    private let playbackManager: TranscriptPlaybackManaging
    private var transcript: TranscriptModel?
    private var previousRange: NSRange?

    private var canScrollToDismiss = true

    private var isSearching = false
    private var searchIndicesResult: [Int] = []
    private var currentSearchIndex = 0
    private var searchTerm: String?

    private let debounce = Debounce(delay: Constants.defaultDebounceTime)

    private var kmpSearch: KMPSearch?

    private var transcriptManager: TranscriptManager?

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

    public override func viewDidLoad() {
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
    }

    func didDisappear() {
        track(.transcriptDismissed)
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    func setHasGeneratedTranscripts(_ value: Bool) {
        let topMargin = showFromEpisode ? 24.0 : 0.0

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

        stackView.addArrangedSubview(closeButton)
        stackView.addArrangedSubview(UIView())

        if FeatureFlag.shareTranscripts.enabled {
            stackView.addArrangedSubview(shareButton)
        }

        if showFromEpisode {
            stackView.addArrangedSubview(playButton)
        }

        stackView.addArrangedSubview(searchButton)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let topMargin = showFromEpisode ? 24.0 : 0.0
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
        guard let transcript = transcript else { return }

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

    private lazy var bannerView: UIView = {
        let view = UIView()
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = L10n.generatedTranscriptsBanner
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = showFromEpisode ? ThemeColor.primaryText01() : .white.withAlphaComponent(0.5)
        label.backgroundColor = .clear
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
        closeButton.tintColor = showFromEpisode ? ThemeColor.primaryText01() : ThemeColor.primaryIcon02()
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return closeButton
    }()

    private lazy var searchButton: RoundButton = {
        let titleColor = showFromEpisode ? ThemeColor.primaryText01() : .white
        let tintColor = showFromEpisode ? ThemeColor.primaryUi05() : .white.withAlphaComponent(0.2)

        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(top: 4, leading: 12, bottom: 4, trailing: 12)

        let searchButton = RoundButton(type: .system)
        searchButton.setTitle(L10n.search, for: .normal)
        searchButton.addTarget(self, action: #selector(displaySearch), for: .touchUpInside)
        searchButton.setTitleColor(titleColor, for: .normal)
        searchButton.tintColor = tintColor
        searchButton.layer.masksToBounds = true
        searchButton.configuration = configuration
        searchButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        searchButton.titleLabel?.adjustsFontForContentSizeCategory = true
        return searchButton
    }()

    private lazy var playButton: RoundPlayPauseButton = {
        let playButton = RoundPlayPauseButton.makeButton(playbackManager: playbackManager)
        playButton.addTarget(self, action: #selector(playEpisode), for: .touchUpInside)
        playButton.titleLabel?.adjustsFontForContentSizeCategory = true
        return playButton
    }()

    private lazy var shareButton: RoundButton = {
        let titleColor = showFromEpisode ? ThemeColor.primaryText01() : .white
        let tintColor = showFromEpisode ? ThemeColor.primaryUi05() : .white.withAlphaComponent(0.2)

        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(top: 4, leading: 12, bottom: 4, trailing: 12)

        let shareButton = RoundButton(type: .system)
        shareButton.setTitle(L10n.share, for: .normal)
        shareButton.addTarget(self, action: #selector(shareEpisode), for: .touchUpInside)
        shareButton.setTitleColor(titleColor, for: .normal)
        shareButton.tintColor = tintColor
        shareButton.layer.masksToBounds = true
        shareButton.configuration = configuration
        shareButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        shareButton.titleLabel?.adjustsFontForContentSizeCategory = true
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
        (transcriptView as UIScrollView).delegate = self
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()
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
        searchButton.isHidden = true
        errorView.isHidden = true
        activityIndicatorView.startAnimating()
    }

    private func setupShowTranscriptState() {
        transcriptView.isHidden = false
        searchButton.isHidden = false
        errorView.isHidden = true
        activityIndicatorView.stopAnimating()
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
                await MainActor.run {
                    self.setHasGeneratedTranscripts(hasGeneratedTranscripts)
                    UIView.animate(withDuration: 0.25) {
                        if hasGeneratedTranscripts, self.shouldShowPremiumView {
                            self.stackView.alpha = 0
                            self.showGeneratedTranscriptsPremiumOverlay?()
                        } else {
                            self.track(.transcriptShown, properties: ["type": transcript.type, "show_as_webpage": transcript.hasJavascript])
                        }
                        self.bannerView.isHidden = !hasGeneratedTranscripts
                    }
                }
                await show(transcript: transcript, resetPosition: shouldResetPosition)
            } catch {
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
            guard let self = self else { return }
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            refreshText()
            refreshError()
        }
        updateTextMargins()
    }

    public override func viewDidLayoutSubviews() {
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
        self.transcript = transcript
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
        highlightStyle[.foregroundColor] = showFromEpisode ? ThemeColor.primaryText01() : ThemeColor.playerContrast01()

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
        //We disabled the method bellow until we find a way to resync/shift transcript positions
        //addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(updateTranscriptPosition))
    }

    @objc private func updateTranscriptPosition() {
        let position = playbackManager.currentTime()
        guard let transcript else {
            return
        }
        if let cue = transcript.firstCue(containing: position), cue.characterRange != previousRange {
            let range = cue.characterRange
            //Comment this line out if you want to check the player position and cues in range
            //print("Transcript position: \(position) in [\(cue.startTime) <-> \(cue.endTime)]")
            previousRange = range
            transcriptView.attributedText = styleText(transcript: transcript, position: position)
            // adjusting the scroll to range so it shows more text
            let scrollRange = NSRange(location: range.location, length: range.length * 2)
            transcriptView.scrollRangeToVisible(scrollRange)
        } else if let startTime = transcript.cues.first?.startTime, position < startTime {
            previousRange = nil
            transcriptView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }
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

    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any] = [:]) {
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
    }
}

extension TranscriptViewController: TranscriptSearchAccessoryViewDelegate {
    func doneTapped() {
        dismissSearch()
        resetSearch()
        searchView.removeFromSuperview()
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
            let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            let image = UIImage(systemName: buttonState.imageName, withConfiguration: config)?
                .withRenderingMode(.alwaysTemplate)
            setTitle(buttonState.buttonTitle, for: .normal)
            setImage(image, for: .normal)
        }
    }

    static func makeButton(playbackManager: TranscriptPlaybackManaging) -> RoundPlayPauseButton {
        let titleColor = ThemeColor.primaryText01()
        let tintColor = ThemeColor.primaryUi05()

        var  bg = UIBackgroundConfiguration.clear()
        bg.backgroundColor = tintColor
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(top: 4, leading: 12, bottom: 4, trailing: 12)
        configuration.imagePadding = 8.0
        configuration.background = bg
        configuration.baseForegroundColor = ThemeColor.primaryIcon03()

        let playButton = RoundPlayPauseButton(type: .system)
        playButton.playbackManager = playbackManager
        playButton.buttonState = playbackManager.isPlayingEpisode ? .pause : .play
        playButton.setupObservers()
        playButton.setTitleColor(titleColor, for: .normal)
        playButton.tintColor = tintColor
        playButton.layer.masksToBounds = true
        playButton.configuration = configuration
        playButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
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
