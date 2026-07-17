import Swift
import AVFoundation

class PlayerStatusObserver {

    static let shared = {
       return PlayerStatusObserver()
    }()

    private var player: AVPlayer?
    private var timeControlStatusObservation: NSKeyValueObservation?
    private var previousTimeStatus: AVPlayer.TimeControlStatus?

    private var remainingEventsToSkip: UInt = 0

    private init() {
    }

    deinit {
        timeControlStatusObservation?.invalidate()
    }

    func observe(player: AVPlayer) {
        guard self.player != player else {
            return
        }
        timeControlStatusObservation?.invalidate()
        self.player = player
        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updatePlayState()
            }
        }
    }

    func skipNextEvents(_ amount: UInt) {
        remainingEventsToSkip = amount
    }

    private func updatePlayState() {
        guard let player else {
            return
        }
        let currentTimeStatus = player.timeControlStatus
        if previousTimeStatus == nil {
            //ignore first change on load, or changes that are not coming from play/pause
            previousTimeStatus = currentTimeStatus
            return
        }

        guard previousTimeStatus != currentTimeStatus, previousTimeStatus == .paused || previousTimeStatus == .playing else {
            previousTimeStatus = currentTimeStatus
            return
        }
        previousTimeStatus = currentTimeStatus

        if remainingEventsToSkip > 0, currentTimeStatus == .playing || currentTimeStatus == .paused {
            remainingEventsToSkip -= 1
            return
        }

        if let interval = AnalyticsPlaybackHelper.shared.timestampOfLastRemoteAction?.timeIntervalSinceNow,
             abs(interval) < 1 {
            // Do not need to track playback changes made by remote just now
            AnalyticsPlaybackHelper.shared.timestampOfLastRemoteAction = nil
            return
        }

        switch currentTimeStatus {
        case .playing:
            AnalyticsPlaybackHelper.shared.currentSource = .player
            AnalyticsPlaybackHelper.shared.play()
        case .paused:
            AnalyticsPlaybackHelper.shared.currentSource = .player
            AnalyticsPlaybackHelper.shared.pause()
        case .waitingToPlayAtSpecifiedRate:
            break
        @unknown default:
            break
        }
    }
}
