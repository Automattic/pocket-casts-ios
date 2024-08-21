import UIKit
import PocketCastsDataModel

class TranscriptShelfButton: UIButton, CheckTranscriptAvailability {
    var isTranscriptEnabled: Bool {
        get {
            isEnabled
        }

        set {
            isEnabled = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addObservers()
        checkTranscriptAvailability()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addObservers() {
        addTranscriptObservers()
    }
}

protocol CheckTranscriptAvailability: AnyObject {
    var isTranscriptEnabled: Bool { get set }

    func addTranscriptObservers()
    func checkTranscriptAvailability()
}

extension CheckTranscriptAvailability {
    func addTranscriptObservers() {
        NotificationCenter.default.addObserver(forName: Constants.Notifications.episodeTranscriptAvailabilityChanged, object: nil, queue: .main) { [weak self] notification in
            guard let episodeUuid = notification.userInfo?["episodeUuid"] as? String,
                  let isAvailable = notification.userInfo?["isAvailable"] as? Bool,
                  episodeUuid == PlaybackManager.shared.currentEpisode()?.uuid else {
                return
            }

            self?.isTranscriptEnabled = isAvailable
        }

        NotificationCenter.default.addObserver(forName: Constants.Notifications.playbackTrackChanged, object: nil, queue: .main) { [weak self] notification in
            self?.checkTranscriptAvailability()
        }
    }

    func checkTranscriptAvailability() {
        isTranscriptEnabled = false
        let currentEpisode = PlaybackManager.shared.currentEpisode() as? Episode
        currentEpisode?.checkTranscriptAvailability()
    }
}
