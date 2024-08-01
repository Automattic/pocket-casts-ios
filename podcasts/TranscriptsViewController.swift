import UIKit
import PocketCastsUtils

class TranscriptsViewController: PlayerItemViewController {

    let playbackManager: PlaybackManager
    var transcript: TranscriptModel?
    var previousRange: NSRange?

    var canScrollToDismiss = true

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

        view.addSubview(closeButton)
        closeButton.frame = .init(x: 16, y: 0, width: 44, height: 44)
    }

    private lazy var transcriptView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.showsVerticalScrollIndicator = true
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            refreshText()
        }
        updateTextMargins()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTextMargins()
    }

    private func updateTextMargins() {
        let margin = self.view.readableContentGuide.layoutFrame.minX + 8
        transcriptView.textContainerInset = .init(top: 0.75 * Sizes.topGradientHeight, left: margin, bottom: 0.7 * Sizes.bottomGradientHeight, right: margin)
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

    private func styleText(transcript: TranscriptModel, position: Double = -1) -> NSAttributedString {
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

        if position != -1, let range = transcript.firstCue(containing: position)?.characterRange {
            formattedText.addAttributes(highlightStyle, range: range)
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
