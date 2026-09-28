import UIKit
import PocketCastsDataModel

class TranscriptShelfButton: UIButton, CheckTranscriptAvailability {
    var hasGeneratedTranscripts: Bool = false
    var isTranscriptEnabled: Bool {
        didSet {
            imageView?.tintColor = isTranscriptEnabled ? ThemeColor.playerContrast02() : ThemeColor.playerContrast04()
        }
    }
    var transcriptObservers: [NSObjectProtocol] = []

    override init(frame: CGRect) {
        isTranscriptEnabled = false
        super.init(frame: frame)
        addObservers()
        checkTranscriptAvailability()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeTranscriptObservers()
    }

    func addObservers() {
        addTranscriptObservers()
    }
}

protocol CheckTranscriptAvailability: AnyObject {
    var isTranscriptEnabled: Bool { get set }
    var hasGeneratedTranscripts: Bool { get set }
    var transcriptObservers: [NSObjectProtocol] { get set }

    func addTranscriptObservers()
    func removeTranscriptObservers()
    func checkTranscriptAvailability()
}

extension CheckTranscriptAvailability {
    func addTranscriptObservers() {
        transcriptObservers.append(NotificationCenter.default.addObserver(forName: Constants.Notifications.episodeTranscriptAvailabilityChanged, object: nil, queue: .main) { [weak self] notification in
            guard let episodeUuid = notification.userInfo?["episodeUuid"] as? String,
                  let isAvailable = notification.userInfo?["isAvailable"] as? Bool,
                  let hasGeneratedTranscripts = notification.userInfo?["hasGeneratedTranscripts"] as? Bool,
                  episodeUuid == PlaybackManager.shared.currentEpisode?.uuid else {
                return
            }

            self?.isTranscriptEnabled = isAvailable
            self?.hasGeneratedTranscripts = hasGeneratedTranscripts
        })

        transcriptObservers.append(NotificationCenter.default.addObserver(forName: Constants.Notifications.playbackTrackChanged, object: nil, queue: .main) { [weak self] _ in
            self?.checkTranscriptAvailability()
        })
    }

    func removeTranscriptObservers() {
        transcriptObservers.forEach { NotificationCenter.default.removeObserver($0) }
        transcriptObservers.removeAll()
    }

    func checkTranscriptAvailability() {
        isTranscriptEnabled = false
        hasGeneratedTranscripts = false
        let currentEpisode = PlaybackManager.shared.currentEpisode as? Episode
        currentEpisode?.checkTranscriptAvailability()
    }
}
