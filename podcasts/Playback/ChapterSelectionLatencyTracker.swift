import Foundation

/// Measures how long it takes for playback to actually resume at a tapped
/// chapter's position, so `player_chapter_selected` can report
/// `playback_start_latency_ms` (see Android PR pocket-casts-android#5522).
///
/// Flow: `begin` at tap time, then `arm` once the seek to the target position
/// has been issued. The tracker watches playback notifications until playback
/// is running at the target position and reports the raw elapsed time since the
/// tap — matching Android, which measures `tapMark.elapsedNow()` with no
/// exclusions (any generated-chapter alignment wait is included).
final class ChapterSelectionLatencyTracker {

    /// How long to wait, once the seek has been issued, for playback to resume
    /// before giving up and reporting a nil latency. Mirrors Android's
    /// `PLAYBACK_START_TIMEOUT`.
    private let playbackTimeout: TimeInterval = 5

    /// Safety net used before `arm` is called: covers the fingerprint resolve
    /// timeout (`FingerprintConstants.onDemandSeekTimeoutSeconds`) plus the
    /// playback timeout, so the tracker always resolves and never leaks — e.g.
    /// if the resolve never seeks because the episode changed. Mirrors Android's
    /// alignment timeout + playback timeout structure.
    private let safetyTimeout: TimeInterval = FingerprintConstants.onDemandSeekTimeoutSeconds + 5

    /// Playback is considered to have reached the target once it is playing at or
    /// past the target position. The tolerance absorbs the `ceil` rounding the
    /// seek applies and small timeline drift.
    private let positionTolerance: TimeInterval = 1.5

    private var observers: [NSObjectProtocol] = []
    private var timeoutWorkItem: DispatchWorkItem?

    private var tapDate: Date?
    private var episodeUuid: String?
    private var targetTime: TimeInterval?
    private var targetDuration: TimeInterval = 0
    private var completion: ((Int?) -> Void)?

    /// Begin measuring for a chapter tapped at `tapDate` on `episodeUuid`.
    /// `completion` fires exactly once, on the main queue, with the latency in
    /// milliseconds — or nil if playback didn't resume before the timeout.
    func begin(tapDate: Date, episodeUuid: String, completion: @escaping (Int?) -> Void) {
        cancel()

        self.tapDate = tapDate
        self.episodeUuid = episodeUuid
        self.completion = completion

        let names = [Constants.Notifications.playbackStarted, Constants.Notifications.playbackProgress]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.checkPlaybackResumed()
            }
        }

        scheduleTimeout(after: safetyTimeout)
    }

    /// Arm detection once the seek has been issued. `targetTime` is the position
    /// playback should reach and `targetDuration` the tapped chapter's length —
    /// together they bound the window that counts as "reached", so a stray
    /// progress tick from the pre-seek position (always in another chapter) can't
    /// match.
    func arm(targetTime: TimeInterval, targetDuration: TimeInterval) {
        guard completion != nil else { return }
        self.targetTime = targetTime
        self.targetDuration = targetDuration
        // The seek has been issued; the latency clock now runs until playback
        // resumes, so restart the timeout to cover just that window.
        scheduleTimeout(after: playbackTimeout)
        // A seek that completes before the first notification (e.g. a fast cache
        // hit while already playing) would otherwise be missed until the next tick.
        checkPlaybackResumed()
    }

    func cancel() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        tapDate = nil
        episodeUuid = nil
        targetTime = nil
        targetDuration = 0
        completion = nil
    }

    private func scheduleTimeout(after interval: TimeInterval) {
        timeoutWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.finish(latencyMs: nil) }
        timeoutWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: item)
    }

    private func checkPlaybackResumed() {
        guard let tapDate, let targetTime,
              PlaybackManager.shared.playing(),
              PlaybackManager.shared.currentEpisode()?.uuid == episodeUuid else {
            return
        }

        // Only count playback that has actually landed inside the tapped chapter's
        // window; the pre-seek position sits in a different chapter and is excluded.
        let currentTime = PlaybackManager.shared.currentTime()
        guard currentTime >= targetTime - positionTolerance,
              currentTime <= targetTime + targetDuration + positionTolerance else {
            return
        }

        // Raw tap-to-playback time, matching Android's `tapMark.elapsedNow()`.
        let elapsed = Date().timeIntervalSince(tapDate)
        finish(latencyMs: Int(max(0, elapsed) * 1000))
    }

    private func finish(latencyMs: Int?) {
        guard let completion else { return }
        cancel()
        completion(latencyMs)
    }
}
