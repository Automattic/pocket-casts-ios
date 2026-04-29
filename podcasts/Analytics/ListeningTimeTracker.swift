import AVFoundation
import EventHorizonSDK
import Foundation
import PocketCastsDataModel
import UIKit

/// Tracks wall-clock listening time per playback session and emits a `ListeningTimeEvent`
/// when the session ends. State lives in memory only — there is no local DB, so events
/// that don't reach `stop()` (force-quit, OS suspension) are lost by design.
final class ListeningTimeTracker {
    static let shared = ListeningTimeTracker()

    private struct Session {
        let startedAt: Date
        let podcastUuid: String
        let episodeUuid: String
        let deviceType: EventHorizonSDK.DeviceType
    }

    private let lock = NSLock()
    private var session: Session?

    private let dateProvider: () -> Date
    private let send: (ListeningTimeEvent) -> Void

    init(
        dateProvider: @escaping () -> Date = Date.init,
        send: @escaping (ListeningTimeEvent) -> Void = { Analytics.send($0) }
    ) {
        self.dateProvider = dateProvider
        self.send = send
    }

    func start(episode: BaseEpisode) {
        lock.lock()
        let now = dateProvider()
        if let active = session, active.episodeUuid == episode.uuid {
            lock.unlock()
            return
        }
        let toEmit = session
        session = Session(
            startedAt: now,
            podcastUuid: episode.parentIdentifier(),
            episodeUuid: episode.uuid,
            deviceType: .current
        )
        lock.unlock()

        if let toEmit {
            emit(session: toEmit, endedAt: now)
        }
    }

    func stop() {
        lock.lock()
        guard let s = session else { lock.unlock(); return }
        session = nil
        lock.unlock()

        emit(session: s, endedAt: dateProvider())
    }

    private func emit(session: Session, endedAt: Date) {
        let durationMs = Int(endedAt.timeIntervalSince(session.startedAt) * 1000)
        guard durationMs > 0 else { return }

        let event = ListeningTimeEvent(
            startedAtMs: Int(session.startedAt.timeIntervalSince1970 * 1000),
            durationMs: durationMs,
            eventUuid: UUID().uuidString.lowercased(),
            podcastUuid: session.podcastUuid,
            episodeUuid: session.episodeUuid,
            deviceType: session.deviceType
        )
        send(event)
    }
}

private extension EventHorizonSDK.DeviceType {
    static var current: EventHorizonSDK.DeviceType {
        if isCarPlayConnected() { return .car }
        return .phone
    }

    private static func isCarPlayConnected() -> Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .carAudio }
    }
}
