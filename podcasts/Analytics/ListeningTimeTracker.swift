import Foundation
import PocketCastsDataModel

/// Tracks wall-clock listening time per playback session and emits a `listening_time`
/// analytics event when the session ends. State lives in memory only — there is no
/// local DB, so events that don't reach `stop()` (force-quit, OS suspension) are lost
/// by design.
final class ListeningTimeTracker {
    static let shared = ListeningTimeTracker()

    private struct Session {
        let startedAt: Date
        let podcastUuid: String
        let episodeUuid: String
        let deviceType: DeviceType
    }

    private let lock = NSLock()
    private var session: Session?

    private let dateProvider: () -> Date
    private let track: (AnalyticsEvent, [AnyHashable: Any]?) -> Void

    init(
        dateProvider: @escaping () -> Date = Date.init,
        track: @escaping (AnalyticsEvent, [AnyHashable: Any]?) -> Void = { Analytics.track($0, properties: $1) }
    ) {
        self.dateProvider = dateProvider
        self.track = track
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
        let durationMs = Int64(endedAt.timeIntervalSince(session.startedAt) * 1000)
        guard durationMs > 0 else { return }

        track(.listeningTime, [
            "started_at_ms": Int64(session.startedAt.timeIntervalSince1970 * 1000),
            "duration_ms": durationMs,
            "event_uuid": UUID().uuidString.lowercased(),
            "podcast_uuid": session.podcastUuid,
            "episode_uuid": session.episodeUuid,
            "device_type": session.deviceType
        ])
    }
}
