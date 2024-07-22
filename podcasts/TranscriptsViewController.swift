import Foundation
import UIKit

class TranscriptsViewController: PlayerItemViewController {

    let playbackManager: PlaybackManager
    var transcript: TranscriptModel?
    var previousRange: NSRange?

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
                transcriptView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
                transcriptView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
            ]
        )

        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate(
            [
                activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ]
        )
    }

    private lazy var transcriptView: UITextView = {
        let textView =  UITextView()
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

    override func willBeAddedToPlayer() {
        updateColors()
        loadTranscript()
        addObservers()
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
    }

    @objc private func update() {
        updateColors()
        loadTranscript()
    }

    private func loadTranscript() {
        activityIndicatorView.startAnimating()
        Task.detached { [weak self] in
            guard let self else {
                return
            }
            let transcriptManager = TranscriptManager(playbackManager: self.playbackManager)
            do {
                let transcript = try await transcriptManager.loadTranscript()
                await show(transcript: transcript)
            } catch {
                await show(error: error)
            }
        }
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

        var standardFont = UIFont.systemFont(ofSize: 18)

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(
          withTextStyle: .body)
          .withDesign(.serif) {
            standardFont = UIFont(descriptor: descriptor, size: 0)
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
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(updateTranscriptPosition))
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
}
