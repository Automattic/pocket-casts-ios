import Foundation
import UIKit

class TranscriptsViewController: PlayerItemViewController {

    let playbackManager: PlaybackManager

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
            guard
                let self,
                let episode = self.playbackManager.currentEpisode(), let podcast = self.playbackManager.currentPodcast,
                let transcripts = try? await ShowInfoCoordinator.shared.loadTranscripts(podcastUuid: podcast.uuid, episodeUuid: episode.uuid),
                let transcript = transcripts.first else {
                await self?.showResult(transcript: "", noTranscript: true, failedLoading: false)
                return
            }

            guard
                let transcriptURL = URL(string: transcript.url),
                let transcriptText = try? String(contentsOf: transcriptURL)
            else {
                await self.showResult(transcript: "", noTranscript: false, failedLoading: true)
                return
            }

            await self.showResult(transcript: transcriptText, noTranscript: false, failedLoading: false)
        }
    }

    private func showResult(transcript: String, noTranscript: Bool, failedLoading: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.activityIndicatorView.stopAnimating()
            if noTranscript {
                self.transcriptView.text = "Transcript not available"
                return
            }
            if failedLoading {
                self.transcriptView.text = "Transcript failed to load"
                return
            }
            self.transcriptView.text = transcript
        }
    }

    private func addObservers() {
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(update))
    }
}
