import UIKit
import PocketCastsDataModel

class TranscriptShelfButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addObservers()
        checkTranscriptAvailability()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(episodeTranscriptAvailabilityChanged), name: Constants.Notifications.episodeTranscriptAvailabilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackTrackChanged), name: Constants.Notifications.playbackTrackChanged, object: nil)
    }

    @objc func playbackTrackChanged() {
        checkTranscriptAvailability()
    }

    @objc func episodeTranscriptAvailabilityChanged(notification: NSNotification) {
        guard let episodeUuid = notification.userInfo?["episodeUuid"] as? String,
              let isAvailable = notification.userInfo?["isAvailable"] as? Bool,
              episodeUuid == PlaybackManager.shared.currentEpisode()?.uuid else {
            return
        }

        isEnabled = isAvailable
    }

    private func checkTranscriptAvailability() {
        isEnabled = false
        let currentEpisode = PlaybackManager.shared.currentEpisode() as? Episode
        currentEpisode?.checkTranscriptAvailability()
    }
}

extension Episode {
    // MARK: - Transcripts

    func checkTranscriptAvailability() {
        Task.init {
            if let transcripts = try? await ShowInfoCoordinator.shared.loadTranscripts(podcastUuid: parentIdentifier(), episodeUuid: uuid) {
                let transcriptsAvailable = !transcripts.isEmpty
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeTranscriptAvailabilityChanged, userInfo: ["episodeUuid": uuid, "isAvailable": transcriptsAvailable])
            }
        }
    }
}
