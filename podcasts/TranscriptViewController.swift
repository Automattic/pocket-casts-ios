import UIKit
import PocketCastsUtils

class TranscriptViewController: PlayerItemViewController {

    private let playbackManager: PlaybackManager
    private var transcript: TranscriptModel?
    private var previousRange: NSRange?

    private var canScrollToDismiss = true

    private var isSearching = false
    private var searchIndicesResult: [Int] = []
    private var currentSearchIndex = 0
    private var searchTerm: String?

    private let debounce = Debounce(delay: Constants.defaultDebounceTime)

    private var kmpSearch: KMPSearch?

    init(playbackManager: PlaybackManager) {
        self.playbackManager = playbackManager
        super.init()
    }

    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.playbackManager = PlaybackManager.shared
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        addObservers()
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

    private func setupViews() {
        view.addSubview(transcriptView)
        NSLayoutConstraint.activate(
            [
                transcriptView.topAnchor.constraint(equalTo: view.topAnchor),
                transcriptView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
        NSLayoutConstraint.activate(
            [
                topGradient.topAnchor.constraint(equalTo: view.topAnchor),
                topGradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                topGradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                topGradient.heightAnchor.constraint(equalToConstant: Sizes.topGradientHeight)
            ]
        )

        view.addSubview(bottomGradient)
        bottomGradient.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                bottomGradient.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                bottomGradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bottomGradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomGradient.heightAnchor.constraint(equalToConstant: Sizes.bottomGradientHeight)
            ]
        )

        view.addSubview(hiddenTextView)

        stackView.addArrangedSubview(closeButton)
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(searchButton)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.widthAnchor.constraint(equalToConstant: 44)
        ])
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

        track(.transcriptSearch)
    }

    private func dismissSearch() {
        isSearching = false

        searchView.textField.resignFirstResponder()

        resignFirstResponder()
    }

    private lazy var transcriptView: UITextView = {
        let textView = UITextView()
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
       TranscriptErrorView { [weak self] in
            self?.retryLoad()
        }
    }()

    private lazy var closeButton: TintableImageButton! = {
        let closeButton = TintableImageButton()
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.tintColor = ThemeColor.primaryIcon02()
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return closeButton
    }()

    private lazy var searchButton: RoundButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(top: 4, leading: 12, bottom: 4, trailing: 12)

        let searchButton = RoundButton(type: .system)
        searchButton.setTitle(L10n.search, for: .normal)
        searchButton.addTarget(self, action: #selector(displaySearch), for: .touchUpInside)
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.tintColor = .white.withAlphaComponent(0.2)
        searchButton.layer.masksToBounds = true
        searchButton.configuration = configuration
        searchButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        searchButton.titleLabel?.adjustsFontForContentSizeCategory = true
        return searchButton
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
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        transcriptView.backgroundColor =  PlayerColorHelper.playerBackgroundColor01()
        transcriptView.textColor = ThemeColor.playerContrast02()
        transcriptView.indicatorStyle = .white
        activityIndicatorView.color = ThemeColor.playerContrast02()
        updateGradientColors()
    }

    private func updateGradientColors() {
        topGradient.updateColors(firstColor: Colors.gradientColor, secondColor: Colors.gradientColor.withAlphaComponent(0))
        bottomGradient.updateColors(firstColor: Colors.gradientColor.withAlphaComponent(0), secondColor: Colors.gradientColor)
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

    private func loadTranscript() {
        setupLoadingState()
        Task.detached { [weak self] in
            guard let self, let episode = playbackManager.currentEpisode(), let podcast = playbackManager.currentPodcast else {
                return
            }

            let transcriptManager = TranscriptManager(episodeUUID: episode.uuid, podcastUUID: podcast.uuid)

            do {
                let transcript = try await transcriptManager.loadTranscript()
                await track(.transcriptShown)
                await show(transcript: transcript)
            } catch {
                await track(.transcriptError, properties: ["error_code": (error as NSError).code])
                await show(error: error)
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
        transcriptView.textContainerInset = .init(top: 0.75 * Sizes.topGradientHeight, left: margin, bottom: bottomContainerInset, right: margin)
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

    private func show(transcript: TranscriptModel) {
        setupShowTranscriptState()
        previousRange = nil
        self.transcript = transcript
        transcriptView.attributedText = styleText(transcript: transcript)
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
            .foregroundColor: ThemeColor.playerContrast02()
        ]

        return normalStyle
    }

    private func styleText(transcript: TranscriptModel, position: Double = -1) -> NSAttributedString {
        let formattedText = NSMutableAttributedString(attributedString: transcript.attributedText)
        formattedText.beginEditing()
        let normalStyle = makeStyle()
        var highlightStyle = normalStyle
        highlightStyle[.foregroundColor] = ThemeColor.playerContrast01()

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
                    let highlightStyle: [NSAttributedString.Key: Any] = [
                        .backgroundColor: UIColor.white.withAlphaComponent(index == currentSearchIndex ? 1 : 0.4),
                        .foregroundColor: index == currentSearchIndex ? UIColor.black : ThemeColor.playerContrast01()
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
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(update))
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
            transcriptView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: adjustmentHeight, right: 0)
            transcriptView.setContentOffset(previousContentOffset, animated: false)
            transcriptView.verticalScrollIndicatorInsets.bottom = show ? adjustmentHeight : bottomContainerInset
        }, completion: { [weak self] _ in
            guard let self else { return }
            transcriptView.setContentOffset(previousContentOffset, animated: false)
        })
    }

    // MARK: - Tracks

    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any] = [:]) {
        var properties = properties

        if let episode = playbackManager.currentEpisode() {
            properties["episode_uuid"] = episode.uuid
            properties["podcast_uuid"] = episode.parentIdentifier()
        }

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
