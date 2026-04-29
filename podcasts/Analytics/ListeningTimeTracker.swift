import AVFoundation
import EventHorizonSDK
import Foundation
import PocketCastsDataModel
import UIKit

/// Tracks wall-clock listening time per playback session and emits one or more
/// `ListeningTimeEvent`s while playback is active.
///
/// Long sessions are auto-truncated into 10-minute segments so a single episode can
/// produce multiple events. Session state is persisted to disk on every heartbeat,
/// so a force-quit, crash, or OS termination loses at most one heartbeat interval
/// of listening time — the orphan is emitted on the next launch via
/// `recoverPendingSession()`.
final class ListeningTimeTracker {
    static let shared = ListeningTimeTracker()

    /// Maximum duration a single emitted event represents. Sessions exceeding this
    /// are split — we emit an intermediate event and continue with a fresh segment
    /// for the same episode.
    static let segmentDurationMs = 10 * 60 * 1000   // 10 minutes
    /// How often the persisted heartbeat is updated. A force-quit loses at most this
    /// much listening time on recovery.
    static let heartbeatInterval: TimeInterval = 15
    /// Defensive cap on a single emitted event. Auto-truncation keeps normal segments
    /// well under this; the cap guards against clock changes and stale recovered state.
    static let maxDurationMs = 12 * 60 * 60 * 1000  // 12 hours

    private struct Session: Codable {
        var startedAt: Date
        let podcastUuid: String
        let episodeUuid: String
        let deviceTypeRaw: String
        var lastHeartbeatAt: Date

        var deviceType: EventHorizonSDK.DeviceType {
            EventHorizonSDK.DeviceType(rawValue: deviceTypeRaw) ?? .phone
        }
    }

    private let lock = NSLock()
    private var session: Session?
    /// Monotonic time at the start of the current segment. Used for duration math so
    /// wall-clock changes mid-session can't corrupt it.
    private var segmentStartedUptime: TimeInterval?
    private var heartbeatTimer: Timer?

    private let dateProvider: () -> Date
    private let uptimeProvider: () -> TimeInterval
    private let send: (ListeningTimeEvent) -> Void
    private let storage: SessionStorage

    init(
        dateProvider: @escaping () -> Date = Date.init,
        uptimeProvider: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        storage: SessionStorage = UserDefaultsSessionStorage(),
        send: @escaping (ListeningTimeEvent) -> Void = { Analytics.send($0) }
    ) {
        self.dateProvider = dateProvider
        self.uptimeProvider = uptimeProvider
        self.storage = storage
        self.send = send
        observeLifecycle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        heartbeatTimer?.invalidate()
    }

    // MARK: - Public API

    func start(episode: BaseEpisode) {
        let now = dateProvider()
        let nowUptime = uptimeProvider()
        let deviceType = EventHorizonSDK.DeviceType.current

        lock.lock()
        if let active = session, active.episodeUuid == episode.uuid {
            lock.unlock()
            return
        }
        let toEmit = session
        let toEmitUptime = segmentStartedUptime
        let new = Session(
            startedAt: now,
            podcastUuid: episode.parentIdentifier(),
            episodeUuid: episode.uuid,
            deviceTypeRaw: deviceType.rawValue,
            lastHeartbeatAt: now
        )
        session = new
        segmentStartedUptime = nowUptime
        persistLocked(new)
        lock.unlock()

        if let toEmit, let toEmitUptime {
            let durationMs = Int((nowUptime - toEmitUptime) * 1000)
            emit(session: toEmit, durationMs: durationMs)
        }

        startHeartbeatTimer()
    }

    func stop() {
        lock.lock()
        guard let s = session, let startUptime = segmentStartedUptime else {
            lock.unlock()
            return
        }
        let durationMs = Int((uptimeProvider() - startUptime) * 1000)
        session = nil
        segmentStartedUptime = nil
        storage.clear()
        lock.unlock()

        stopHeartbeatTimer()
        emit(session: s, durationMs: durationMs)
    }

    /// Emits any session left on disk by a previous launch (force-quit, crash, OS
    /// termination). Call once after Analytics is set up.
    ///
    /// If a new session has already been started in this process, recovery is
    /// skipped — the in-memory session has overwritten the on-disk slot, so what
    /// `storage.load()` would return is no longer the orphan.
    func recoverPendingSession() {
        lock.lock()
        guard session == nil, let data = storage.load() else {
            lock.unlock()
            return
        }
        storage.clear()
        lock.unlock()

        guard let recovered = try? JSONDecoder().decode(Session.self, from: data) else {
            return
        }
        guard recovered.lastHeartbeatAt >= recovered.startedAt else {
            return
        }
        let durationMs = Int(recovered.lastHeartbeatAt.timeIntervalSince(recovered.startedAt) * 1000)
        emit(session: recovered, durationMs: durationMs)
    }

    /// Updates the persisted heartbeat and, if the current segment has reached
    /// `segmentDurationMs`, emits an intermediate event and starts a fresh segment.
    /// Exposed for tests; production callers are the heartbeat timer and lifecycle
    /// notifications.
    func heartbeatTick() {
        let now = dateProvider()
        let nowUptime = uptimeProvider()

        lock.lock()
        guard var s = session, let startUptime = segmentStartedUptime else {
            lock.unlock()
            return
        }
        let segmentMs = Int((nowUptime - startUptime) * 1000)

        if segmentMs >= Self.segmentDurationMs {
            // Persist the new segment first, then emit the previous one — if we
            // crash mid-tick, the worst case is losing the segment we were about
            // to emit, never double-emitting it.
            let toEmit = s
            s.startedAt = now
            s.lastHeartbeatAt = now
            session = s
            segmentStartedUptime = nowUptime
            persistLocked(s)
            lock.unlock()

            emit(session: toEmit, durationMs: segmentMs)
        } else {
            s.lastHeartbeatAt = now
            session = s
            persistLocked(s)
            lock.unlock()
        }
    }

    // MARK: - Private

    private func emit(session: Session, durationMs: Int) {
        guard durationMs > 0 else { return }
        let cappedMs = min(durationMs, Self.maxDurationMs)

        let event = ListeningTimeEvent(
            startedAtMs: Int(session.startedAt.timeIntervalSince1970 * 1000),
            durationMs: cappedMs,
            eventUuid: UUID().uuidString.lowercased(),
            podcastUuid: session.podcastUuid,
            episodeUuid: session.episodeUuid,
            deviceType: session.deviceType
        )
        send(event)
    }

    private func persistLocked(_ session: Session) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        storage.save(data)
    }

    // MARK: - Lifecycle

    private func observeLifecycle() {
#if os(iOS)
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleBackgroundOrResign),
                           name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(handleBackgroundOrResign),
                           name: UIApplication.willResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(handleWillTerminate),
                           name: UIApplication.willTerminateNotification, object: nil)
#endif
    }

    #if os(iOS)
    @objc private func handleBackgroundOrResign() {
        // Best-effort flush: refresh the persisted heartbeat so a subsequent OS-kill
        // loses as little time as possible. Playback often continues in background
        // for an audio app, so we do NOT stop the session here.
        heartbeatTick()
    }

    @objc private func handleWillTerminate() {
        // Graceful shutdown — emit and clear. Won't fire on force-quit.
        stop()
    }
    #endif

    // MARK: - Timer

    private func startHeartbeatTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.heartbeatTimer?.invalidate()
            let timer = Timer(timeInterval: Self.heartbeatInterval, repeats: true) { [weak self] _ in
                self?.heartbeatTick()
            }
            RunLoop.main.add(timer, forMode: .common)
            self.heartbeatTimer = timer
        }
    }

    private func stopHeartbeatTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = nil
        }
    }
}

// MARK: - Storage

protocol SessionStorage {
    func load() -> Data?
    func save(_ data: Data)
    func clear()
}

struct UserDefaultsSessionStorage: SessionStorage {
    func load() -> Data? {
        UserDefaults.standard.data(forKey: Constants.UserDefaults.listeningTimeTrackerSession)
    }

    func save(_ data: Data) {
        UserDefaults.standard.set(data, forKey: Constants.UserDefaults.listeningTimeTrackerSession)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.listeningTimeTrackerSession)
    }
}

// MARK: - Device type

private extension EventHorizonSDK.DeviceType {
    static var current: EventHorizonSDK.DeviceType {
        if isCarPlayConnected() { return .car }
        return .phone
    }

    private static func isCarPlayConnected() -> Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .carAudio }
    }
}
