import UIKit
import PocketCastsUtils

class TranscriptsViewController: PlayerItemViewController {

    private let playbackManager: PlaybackManager
    private var transcript: TranscriptModel?
    private var previousRange: NSRange?

    private var canScrollToDismiss = true

    private var isSearching = false
    private var searchIndicesResult: [Int] = []
    private var currentSearchIndex = 0
    private var searchTerm: String?

    private let debounce = Debounce(delay: Constants.defaultDebounceTime)

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        parent?.view.overrideUserInterfaceStyle = .unspecified
        dismissSearch()
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
                transcriptView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
                transcriptView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
            ]
        )

        transcriptView.textContainerInset = .init(top: 0.75 * Sizes.topGradientHeight, left: 0, bottom: 0.7 * Sizes.bottomGradientHeight, right: 0)
        transcriptView.scrollIndicatorInsets = .init(top: 0.75 * Sizes.topGradientHeight, left: 0, bottom: 0.7 * Sizes.bottomGradientHeight, right: 0)

        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate(
            [
                activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.style = .medium
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicatorView
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
        activityIndicatorView.color = ThemeColor.playerContrast01()
        updateGradientColors()
    }

    private func updateGradientColors() {
        topGradient.updateColors(firstColor: Colors.gradientColor, secondColor: Colors.gradientColor.withAlphaComponent(0))
        bottomGradient.updateColors(firstColor: Colors.gradientColor.withAlphaComponent(0), secondColor: Colors.gradientColor)
    }

    @objc private func update() {
        updateColors()
        resetSearch()
        loadTranscript()
    }

    @objc private func closeTapped() {
        containerDelegate?.dismissTranscript()
    }

    private func loadTranscript() {
        activityIndicatorView.startAnimating()
        Task.detached { [weak self] in
            guard let self, let episode = playbackManager.currentEpisode(), let podcast = playbackManager.currentPodcast else {
                return
            }
            let transcriptManager = TranscriptManager(episodeUUID: episode.uuid, podcastUUID: podcast.uuid)
            do {
                let transcript = try await transcriptManager.loadTranscript()
                await show(transcript: transcript)
            } catch {
                await show(error: error)
            }
        }
    }

    private func resetSearch() {
        searchIndicesResult = []
        currentSearchIndex = 0
        searchView.textField.text = ""
        searchTerm = nil
        updateNumberOfResults()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            refreshText()
        }
    }

    private func refreshText() {
        guard let transcript else {
            return
        }
        transcriptView.attributedText = styleText(transcript: transcript)
    }

    private func show(transcript: TranscriptModel) {
            activityIndicatorView.stopAnimating()
            self.previousRange = nil
            self.transcript = transcript
            transcriptView.attributedText = styleText(transcript: transcript)
    }

    private func styleText(transcript: TranscriptModel, position: Double = 0) -> NSAttributedString {
        let formattedText = NSMutableAttributedString(attributedString: transcript.attributedText)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.lineBreakMode = .byWordWrapping

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

        let highlightStyle: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: standardFont,
            .foregroundColor: ThemeColor.playerContrast01()
        ]

        formattedText.addAttributes(normalStyle, range: NSRange(location: 0, length: formattedText.length))

        if let range = transcript.firstCue(containing: position)?.characterRange {
            formattedText.addAttributes(highlightStyle, range: range)
        }

        if let searchTerm {
            let length = formattedText.length
            let searchTermLength = searchTerm.count
            searchIndicesResult.enumerated().forEach { index, indice in
                if indice + searchTermLength <= length {
                    let highlightStyle: [NSAttributedString.Key: Any] = [
                        .backgroundColor: UIColor.white.withAlphaComponent(index == 0 ? 1 : 0.4),
                        .foregroundColor: index == 0 ? UIColor.black : ThemeColor.playerContrast01()
                    ]

                    formattedText.addAttributes(highlightStyle, range: NSRange(location: indice, length: searchTermLength))
                }

            }
        }



        return formattedText
    }

    private func show(error: Error) {
        activityIndicatorView.stopAnimating()
        guard let transcriptError = error as? TranscriptError else {
            transcriptView.text = "Transcript unknow error"
            return
        }

        transcriptView.text = transcriptError.localizedDescription
    }

    private func addObservers() {
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(update))
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
            highlightSearchMatches()
        }
    }

    func findOccurrences(of term: String) {
        guard let transcriptText = transcript?.attributedText.string,
              !term.isEmpty else {
            resetSearch()
            return
        }

        let kmpSearch = KMPSearch(pattern: term)
        searchIndicesResult = kmpSearch.search(in: transcriptText)
        searchTerm = term
    }

    @MainActor
    func highlightSearchMatches() {
        guard let transcript else { return }

        transcriptView.attributedText = styleText(transcript: transcript)
    }

    @MainActor
    func updateNumberOfResults() {
        guard searchIndicesResult.count > 0 else {
            searchView.updateLabel("")
            return
        }

        searchView.updateLabel("\(currentSearchIndex + 1) of \(searchIndicesResult.count)")
    }

    // MARK: - Constants

    private enum Sizes {
        static let topGradientHeight: CGFloat = 60
        static let bottomGradientHeight: CGFloat = 60
    }

    private enum Colors {
        static var gradientColor: UIColor {
            PlayerColorHelper.playerBackgroundColor01()
        }
    }
}

extension TranscriptsViewController: UIScrollViewDelegate {

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

extension TranscriptsViewController: TranscriptSearchAccessoryViewDelegate {
    func doneTapped() {
        dismissSearch()
        searchView.removeFromSuperview()
    }

    func searchButtonTapped() {
        becomeFirstResponder()
    }

    func search(_ term: String) {
        guard !term.isEmpty else {
            resetSearch()
            return
        }

        debounce.call { [weak self] in
            self?.performSearch(term)
        }
    }

    func previousMatch() {

    }

    func nextMatch() {

    }
}

private class RoundButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
    }
}
