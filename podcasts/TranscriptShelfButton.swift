import UIKit

class TranscriptShelfButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addObservers()
        playingStateDidChange()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(playingStateDidChange), name: Constants.Notifications.episodeTranscriptAvailabilityChanged, object: nil)
    }

    @objc func playingStateDidChange() {
        isEnabled = PlaybackManager.shared.transcriptsAvailable
    }
}
