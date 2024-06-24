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
        updateColors()
        loadTranscript()
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
    }

    private lazy var transcriptView: UITextView = {
        let textView =  UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        return textView
    }()

    override func willBeAddedToPlayer() {
        updateColors()
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
        transcriptView.textColor = PlayerColorHelper.playerHighlightColor01(for: Theme.sharedTheme.activeTheme)
    }

    private func loadTranscript() {
        Task.detached { [weak self] in
            guard
                let self,
                let episode = self.playbackManager.currentEpisode(), let podcast = self.playbackManager.currentPodcast,
                let transcripts = try? await ShowInfoCoordinator.shared.loadTranscripts(podcastUuid: podcast.uuid, episodeUuid: episode.uuid),
                let transcript = transcripts.first,
                let transcriptURL = URL(string: transcript.url),
                let transcriptText = try? String(contentsOf: transcriptURL)
            else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.transcriptView.text = transcriptText
            }
        }
    }
}
