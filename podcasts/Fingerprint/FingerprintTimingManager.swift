import Foundation
import PocketCastsDataModel
import PocketCastsUtils

/// Owns the playback↔reference time mapping for the episode currently being
/// fingerprinted, and drives the background work that produces it: decoding and
/// matching run on `FingerprintStreamProcessor` (the continuous transcript pass)
/// and `FingerprintRegionProcessor` (bounded one-shot resolves).
@MainActor
final class FingerprintTimingManager: NSObject {

    // MARK: - Public Types

    enum State {
        case idle
        case preparing
        case active(coverage: Int)
        case failed(Error)
        case unavailable

        var analyticsName: String {
            switch self {
            case .idle: return "idle"
            case .preparing: return "preparing"
            case .active: return "active"
            case .failed: return "failed"
            case .unavailable: return "unavailable"
            }
        }
    }

    /// Outcome of a one-shot resolve. `reason` on `.unresolved` is a stable
    /// analytics token the caller reports and can key fallback behavior on.
    enum ChapterSeekResult: Sendable {
        case resolved(playbackTime: Double, usedPrior: Bool, isStreaming: Bool, resolveDurationMs: Int)
        case unresolved(reason: String, isStreaming: Bool)
    }

    /// Everything a fingerprint run needs from a `BaseEpisode`, captured as plain
    /// values so the database model object stays with its caller.
    struct EpisodeRequest: Sendable {
        let episodeUuid: String
        let podcastUuid: String
        let duration: Double
        let audioFileURL: URL
        /// True when `audioFileURL` points at a streaming buffer that may still be
        /// growing. The fingerprint loop polls for new bytes instead of quitting
        /// at EOF.
        let isStreaming: Bool
        /// On-disk path of the reference fingerprint file, used to validate the
        /// persistent mapping cache via file identity (size+mtime).
        let referenceFilePath: String
    }

    // MARK: - Singleton

    static let shared = FingerprintTimingManager()

    // MARK: - Public Properties

    private(set) var state: State = .idle

    /// The committed mapping, republished after every commit.
    var snapshot: MappingSnapshot { main.snapshot }

    // MARK: - Internal Types

    private struct GenerationContext {
        let request: EpisodeRequest
        /// Raw bytes of the reference fingerprint JSON, used to validate the
        /// persistent mapping cache via SHA-256 and to warm-start a resolve.
        let referenceData: Data
        /// Total duration of the reference timeline, used to gate the persistent
        /// mapping cache on full coverage.
        let referenceDuration: Double
    }

    /// What the two one-shot resolves want differently, which all follows from what
    /// their audio is likely to be doing: a chapter's episode is playing, so its
    /// audio is already local, while a bookmark's is often still downloading.
    private enum ResolveKind: Sendable {
        case chapter
        case bookmark

        /// Only a bookmark waits for the streaming buffer to reach the search window.
        var waitsForBufferedRegion: Bool { self == .bookmark }
    }

    private struct WarmPrior: Sendable {
        let referenceData: Data?
        let estimatedPlayback: Double?
    }

    // MARK: - Private State

    private let regionProcessor = FingerprintRegionProcessor()
    private var streamProcessor: FingerprintStreamProcessor?

    private var context: GenerationContext?

    /// Accumulator backing the continuous transcript mapping (playback↔reference
    /// plus drift-filter state). The one-shot resolves use their own scratch
    /// accumulator and never touch this one.
    private var main = MappingAccumulator()

    /// Reference resolution (disk → server) and the decode/match run. Split so a
    /// mid-episode restart can re-anchor the stream without re-fetching.
    private var prepareTask: Task<Void, Never>?
    private var streamTask: Task<Void, Never>?

    /// The one-shot chapter resolve. Cancelling it supersedes it (last tap wins).
    /// Bookmark resolves are owned by their caller, so they neither supersede nor
    /// are superseded by this.
    private var chapterResolveTask: Task<Void, Never>?

    private var lastProgressPosition: Double = -1

    private var preparationStartDate: Date?
    private var hasReachedActive = false
    private var hasEmittedPreparationStarted = false

    // MARK: - Init

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEpisodeDownloaded(_:)),
            name: Constants.Notifications.episodeDownloaded,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackProgress),
            name: Constants.Notifications.playbackProgress,
            object: nil
        )
    }

    // MARK: - Public API

    func prepareForCurrentEpisode() {
        resetState()
        state = .idle

        guard FeatureFlag.syncedTranscripts.enabled else {
            state = .unavailable
            track(.syncedTranscriptsUnavailable, properties: ["reason": "feature_disabled"])
            return
        }

        guard let episode = PlaybackManager.shared.currentEpisode() else {
            state = .unavailable
            track(.syncedTranscriptsUnavailable, properties: ["reason": "no_episode"])
            return
        }

        let request = Self.makeRequest(for: episode)
        prepareTask = Task { [weak self] in
            await self?.prepare(request)
        }
    }

    /// Cancel any in-flight reference fetch and streaming fingerprint work, discard
    /// the current context and mappings, and return to `.idle`. Called when the
    /// transcript view is torn down so we don't keep burning CPU/memory on audio
    /// the listener is no longer looking at.
    func stop() {
        resetState()
        state = .idle
        FileLog.shared.addMessage("FingerprintTimingManager: stopped")
    }

    func referenceTime(forPlaybackTime playbackTime: Double) -> Double? {
        Self.interpolate(
            time: playbackTime,
            in: main.snapshot.playbackToReference,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        )
    }

    func playbackTime(forReferenceTime referenceTime: Double) -> Double? {
        Self.interpolate(
            time: referenceTime,
            in: main.snapshot.referenceToPlayback,
            keyPath: \.referenceTime,
            valuePath: \.playbackTime
        )
    }

    /// Whether `playbackTime` sits on confidently-matched content — bracketed by
    /// committed anchors no more than `highlightMaxGapSeconds` apart.
    ///
    /// Highlighting keys off this so it only ever runs while we're sure where we
    /// are. Real content commits anchors every second or two, so a sparse "quick
    /// red" gap stays under the bound and still counts as matched. A dynamic ad
    /// (absent from the reference fingerprint, so no anchors commit across it)
    /// opens a wide gap — or leaves no committed anchor ahead of the play-head at
    /// all — so the instant playback crosses the last matched anchor this returns
    /// false and highlighting stops, with no ad-detection step to lag behind.
    func isWithinMatchedContent(forPlaybackTime playbackTime: Double) -> Bool {
        Self.isWithinMatchedContent(forPlaybackTime: playbackTime, in: main.snapshot.playbackToReference)
    }

    /// The reference time for `playbackTime`, but only when it's on matched content
    /// (see `isWithinMatchedContent`). Both halves read the same snapshot, so the
    /// highlight tick can't see the gate and the interpolation disagree.
    func matchedReferenceTime(forPlaybackTime playbackTime: Double) -> Double? {
        let entries = main.snapshot.playbackToReference
        guard Self.isWithinMatchedContent(forPlaybackTime: playbackTime, in: entries) else { return nil }
        return Self.interpolate(
            time: playbackTime,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        )
    }

    // MARK: - Notifications

    /// When an episode download completes while the transcript flow has already requested
    /// preparation, retry. If we previously gave up because no local file existed, or were
    /// processing a partial streaming buffer, we now have a complete file to fingerprint.
    @objc private func handleEpisodeDownloaded(_ notification: Notification) {
        guard let downloadedUuid = notification.object as? String,
              let currentUuid = PlaybackManager.shared.currentEpisode()?.uuid,
              currentUuid == downloadedUuid else { return }
        if case .active = state { return }

        FileLog.shared.addMessage(
            "FingerprintTimingManager: episode \(downloadedUuid) finished downloading — re-preparing"
        )
        prepareForCurrentEpisode()
    }

    /// Re-anchor fingerprint generation to wherever the listener is now: if playback
    /// jumps suddenly (seek/skip), or drifts beyond the mapped range, restart the
    /// stream from the new position so coverage stays close to what's playing.
    @objc private func handlePlaybackProgress() {
        let playbackTime = PlaybackManager.shared.currentTime()
        guard playbackTime >= 0,
              let ctx = context,
              ctx.request.episodeUuid == PlaybackManager.shared.currentEpisode()?.uuid else { return }

        if lastProgressPosition >= 0 {
            let delta = abs(playbackTime - lastProgressPosition)
            if delta > FingerprintConstants.restartDeltaSeconds {
                #if DEBUG
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: playback jumped \(String(format: "%.1f", delta))s — restarting from \(String(format: "%.1f", playbackTime))s"
                )
                #endif
                restart(from: playbackTime, context: ctx)
                lastProgressPosition = playbackTime
                return
            }
        }
        lastProgressPosition = playbackTime

        if isWithinMappedRange(playbackTime) { return }

        // If we haven't produced any anchors yet, the current stream is still
        // building the first window around the listener's initial position —
        // restarting every progress tick (which happens each second while the
        // map is empty) cancels that in-flight work before it can finish. The
        // delta-based branch above still catches real seeks. Once we have
        // coverage the drift-restart resumes as before.
        if main.snapshot.isEmpty { return }

        #if DEBUG
        FileLog.shared.addMessage(
            "FingerprintTimingManager: playback at \(String(format: "%.1f", playbackTime))s outside mapped range — restarting"
        )
        #endif
        restart(from: playbackTime, context: ctx)
    }

    private func isWithinMappedRange(_ playbackTime: Double) -> Bool {
        guard let first = main.snapshot.playbackToReference.first,
              let last = main.snapshot.playbackToReference.last else { return false }
        let margin = FingerprintConstants.playbackRangeMarginSeconds
        return playbackTime >= first.playbackTime - margin
            && playbackTime <= last.playbackTime + margin
    }

    /// Cancel the in-flight stream and start a new one anchored at `position`.
    /// Existing mappings are kept — they're still valid, we just refocus
    /// coverage growth around the listener's new position. Filter state is
    /// reset because the new stream's first matches live in a region that has
    /// no rate relationship to the old trusted anchor.
    private func restart(from position: Double, context ctx: GenerationContext) {
        main.resetFilterState()
        startStream(context: ctx, fromPosition: position)
    }

    // MARK: - On-demand chapter seek

    /// Resolve a generated chapter's reference-timeline `referenceTime` to the
    /// playback-timeline position where that content actually occurs in the
    /// listener's audio (which dynamic ads have shifted), by fingerprinting a
    /// bounded region of the local file around the expected area and matching it
    /// against the reference.
    ///
    /// This is a one-shot, side-effect-free operation: it uses its own reference
    /// data, matcher, and scratch mapping, and never mutates the continuous
    /// transcript mapping, `context`, or `state`. A second call supersedes any
    /// still-running one (last tap wins), and a superseded resolve never calls back.
    func resolvePlaybackTime(
        forReferenceTime referenceTime: Double,
        episode: BaseEpisode,
        completion: @escaping @MainActor (ChapterSeekResult) -> Void
    ) {
        chapterResolveTask?.cancel()
        let request = Self.makeRequest(for: episode)

        chapterResolveTask = Task { [weak self] in
            guard let self else { return }
            let result = await Self.withTimeout(FingerprintConstants.onDemandSeekTimeoutSeconds) {
                await self.performResolve(request: request, referenceTime: referenceTime, kind: .chapter)
            }
            guard !Task.isCancelled else { return }
            completion(result ?? .unresolved(reason: "timeout", isStreaming: request.isStreaming))
        }
    }

    /// Cancel any in-flight one-shot chapter resolve without delivering a result.
    /// Called on view teardown so a backgrounded chapters list can't seek later.
    func cancelPendingChapterResolve() {
        chapterResolveTask?.cancel()
        chapterResolveTask = nil
    }

    /// Resolve a bookmark's reference-timeline position to where that content
    /// actually sits in this listener's audio, so playback can start there.
    ///
    /// The same one-shot resolve as `resolvePlaybackTime`, differing only in what a
    /// bookmark's audio is likely to be doing — see `ResolveKind.bookmark`. It keeps
    /// no state of its own, so it neither supersedes nor is superseded by a chapter
    /// resolve; the caller owns the lifetime, and cancelling its task stops the
    /// decode at the next chunk.
    nonisolated func resolveBookmarkPlaybackTime(
        forReferenceTime referenceTime: Double,
        episode: BaseEpisode
    ) async -> ChapterSeekResult {
        let request = Self.makeRequest(for: episode)
        let result = await Self.withTimeout(FingerprintConstants.bookmarkSeekTimeoutSeconds) {
            await self.performResolve(request: request, referenceTime: referenceTime, kind: .bookmark)
        }
        return result ?? .unresolved(reason: "timeout", isStreaming: request.isStreaming)
    }

    nonisolated private func performResolve(
        request: EpisodeRequest,
        referenceTime: Double,
        kind: ResolveKind
    ) async -> ChapterSeekResult {
        let startDate = Date()

        // Snapshot the warm prior (if the transcript flow already has a mapping
        // for this episode): its reference data lets us skip disk/network, and the
        // existing mapping estimates the ad offset at the target so we can tighten
        // the search window.
        let prior = await warmPrior(forReferenceTime: referenceTime, episodeUuid: request.episodeUuid)

        guard let reference = await resolveReference(for: request, warm: prior.referenceData) else {
            return .unresolved(reason: "no_reference", isStreaming: false)
        }
        if Task.isCancelled { return .unresolved(reason: "timeout", isStreaming: false) }
        guard request.duration > 0 else { return .unresolved(reason: "no_reference", isStreaming: false) }

        let usedPrior = prior.estimatedPlayback != nil
        let window = Self.searchWindow(referenceTime: referenceTime, estimatedPlayback: prior.estimatedPlayback)

        // A bookmark's episode is often still arriving: playing it starts a
        // stream-and-cache download that fills the buffer sequentially from byte 0,
        // so the window we want only becomes readable once that prefix reaches it.
        if kind.waitsForBufferedRegion, request.isStreaming {
            await regionProcessor.waitForBufferedRegion(
                audioFileURL: request.audioFileURL,
                coveringSeconds: window.end,
                deadline: startDate.addingTimeInterval(FingerprintConstants.bookmarkSeekBufferWaitSeconds)
            )
        }
        if Task.isCancelled { return .unresolved(reason: "timeout", isStreaming: request.isStreaming) }

        do {
            let scratch = try await regionProcessor.match(
                audioFileURL: request.audioFileURL,
                reference: reference.fingerprint,
                episodeUuid: request.episodeUuid,
                audioDuration: request.duration,
                startSeconds: Self.alignToWindowGrid(window.start),
                endSeconds: window.end
            )
            guard scratch.snapshot.playbackToReference.count >= FingerprintConstants.onDemandSeekMinAnchors,
                  let playback = Self.interpolate(
                      time: referenceTime,
                      in: scratch.snapshot.referenceToPlayback,
                      keyPath: \.referenceTime,
                      valuePath: \.playbackTime
                  ) else {
                return .unresolved(reason: "no_match", isStreaming: request.isStreaming)
            }
            let resolveDurationMs = Self.elapsedMs(since: startDate)
            // Comparable across platforms: Android fingerprints eagerly and iOS
            // reactively on tap, but both report the calculation time here, decoupled
            // from `playerChapterSelected` (the tap) which stays untouched.
            Analytics.track(.playerChapterFingerprintCalculated, properties: [
                "duration_ms": resolveDurationMs,
                "is_streaming": request.isStreaming,
                "episode_uuid": request.episodeUuid,
                "podcast_uuid": request.podcastUuid
            ])
            return .resolved(
                playbackTime: max(referenceTime, playback),
                usedPrior: usedPrior,
                isStreaming: request.isStreaming,
                resolveDurationMs: resolveDurationMs
            )
        } catch is CancellationError {
            return .unresolved(reason: "timeout", isStreaming: request.isStreaming)
        } catch FingerprintStreamError.regionUnavailable {
            return .unresolved(reason: "region_not_local", isStreaming: request.isStreaming)
        } catch FingerprintStreamError.noUsableCheckpoints {
            return .unresolved(reason: "no_reference", isStreaming: request.isStreaming)
        } catch {
            return .unresolved(reason: "no_match", isStreaming: request.isStreaming)
        }
    }

    // MARK: - On-demand bookmark position resolve

    /// Resolves a playback-timeline position (e.g. a bookmark's time) to the
    /// reference timeline, so reference-timed content like a generated
    /// transcript can be read at the right spot despite dynamic-ad shifting.
    ///
    /// Like `resolvePlaybackTime` this is one-shot and side-effect-free.
    ///
    /// Returns nil when no confident match is found (no reference, audio not
    /// local, timeout) — callers should fall back to the raw playback time.
    nonisolated func resolveReferenceTime(forPlaybackTime playbackTime: Double, episode: BaseEpisode) async -> Double? {
        let request = Self.makeRequest(for: episode)
        let startDate = Date()

        // Warm fast path: interpolate off the continuous transcript mapping when
        // it already confidently covers this position.
        let warm: Double? = await MainActor.run {
            guard let ctx = self.context, ctx.request.episodeUuid == request.episodeUuid else { return nil }
            return self.matchedReferenceTime(forPlaybackTime: playbackTime)
        }
        if let warm {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: bookmark resolve matched off the live mapping for \(request.episodeUuid) — "
                    + "local file time \(String(format: "%.1f", playbackTime))s → "
                    + "reference time \(String(format: "%.1f", warm))s"
            )
            return warm
        }

        let outcome: Double?? = await Self.withTimeout(FingerprintConstants.bookmarkResolveTimeoutSeconds) {
            await self.performReferenceResolve(request: request, playbackTime: playbackTime, startDate: startDate)
        }
        return outcome.flatMap { $0 }
    }

    nonisolated private func performReferenceResolve(
        request: EpisodeRequest,
        playbackTime: Double,
        startDate: Date
    ) async -> Double? {
        let warmData = await warmReferenceData(forEpisodeUuid: request.episodeUuid)
        guard let reference = await resolveReference(for: request, warm: warmData), !Task.isCancelled else {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: bookmark resolve gave up for \(request.episodeUuid) — no usable reference"
            )
            return nil
        }
        guard request.duration > 0 else { return nil }

        let start = Self.alignToWindowGrid(
            max(0, playbackTime - FingerprintConstants.bookmarkResolveBackwardSeconds)
        )
        let end = playbackTime + FingerprintConstants.bookmarkResolveForwardSeconds

        let scratch = try? await regionProcessor.match(
            audioFileURL: request.audioFileURL,
            reference: reference.fingerprint,
            episodeUuid: request.episodeUuid,
            audioDuration: request.duration,
            startSeconds: start,
            endSeconds: end
        )

        guard let scratch,
              scratch.snapshot.playbackToReference.count >= FingerprintConstants.bookmarkResolveMinAnchors,
              let referenceTime = Self.interpolate(
                  time: playbackTime,
                  in: scratch.snapshot.playbackToReference,
                  keyPath: \.playbackTime,
                  valuePath: \.referenceTime
              ) else {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: bookmark resolve found no confident match "
                    + "at local file time \(String(format: "%.1f", playbackTime))s for \(request.episodeUuid) "
                    + "(\(scratch?.snapshot.playbackToReference.count ?? 0) anchors, took \(Self.elapsedMs(since: startDate))ms)"
            )
            return nil
        }

        FileLog.shared.addMessage(
            "FingerprintTimingManager: bookmark resolve matched for \(request.episodeUuid) — "
                + "local file time \(String(format: "%.1f", playbackTime))s → "
                + "reference time \(String(format: "%.1f", referenceTime))s "
                + "(\(scratch.snapshot.playbackToReference.count) anchors, took \(Self.elapsedMs(since: startDate))ms)"
        )
        return referenceTime
    }

    /// Read-only peek at the continuous run's state, for a resolve that may be
    /// able to warm-start off it.
    nonisolated private func warmPrior(forReferenceTime referenceTime: Double, episodeUuid: String) async -> WarmPrior {
        await MainActor.run {
            guard let ctx = self.context, ctx.request.episodeUuid == episodeUuid else {
                return WarmPrior(referenceData: nil, estimatedPlayback: nil)
            }
            return WarmPrior(
                referenceData: ctx.referenceData,
                estimatedPlayback: self.playbackTime(forReferenceTime: referenceTime)
            )
        }
    }

    /// The reference bytes the continuous run already holds for this episode, if
    /// any — enough to skip disk and network when no offset estimate is needed.
    nonisolated private func warmReferenceData(forEpisodeUuid episodeUuid: String) async -> Data? {
        await MainActor.run {
            guard let ctx = self.context, ctx.request.episodeUuid == episodeUuid else { return nil }
            return ctx.referenceData
        }
    }

    // MARK: - Debug

    #if DEBUG
    var totalDuration: Double? { context?.request.duration }

    func debugMappingSnapshot() -> [TimeMappingEntry] { main.snapshot.playbackToReference }

    /// Candidates that reached the drift filter but were rejected. The debug
    /// overlay uses this to distinguish "matcher never fired here" from
    /// "matcher fired but everything was filtered out as noise".
    func debugRejectionsSnapshot() -> [TimeMappingEntry] { main.rejections }
    #endif

    // MARK: - State Management

    private func resetState() {
        prepareTask?.cancel()
        prepareTask = nil
        streamTask?.cancel()
        streamTask = nil
        streamProcessor = nil
        context = nil
        main = MappingAccumulator()
        lastProgressPosition = -1
        preparationStartDate = nil
        hasReachedActive = false
        hasEmittedPreparationStarted = false
    }

    private func track(_ event: AnalyticsEvent, properties: [String: Sendable] = [:]) {
        var properties = properties
        if let episodeUuid = context?.request.episodeUuid {
            properties["episode_uuid"] = episodeUuid
        }
        Analytics.track(event, properties: properties)
    }

    private var preparationDurationMs: Int {
        guard let start = preparationStartDate else { return 0 }
        return Self.elapsedMs(since: start)
    }

    // MARK: - Track Preparation

    private func prepare(_ request: EpisodeRequest) async {
        var loaded = await Self.loadReference(atPath: request.referenceFilePath)

        if loaded == nil {
            preparationStartDate = Date()
            state = .preparing
            track(.syncedTranscriptsPreparationStarted, properties: [
                "episode_uuid": request.episodeUuid,
                "episode_duration_seconds": request.duration
            ])
            hasEmittedPreparationStarted = true
            FileLog.shared.addMessage(
                "FingerprintTimingManager: fetching reference from server for \(request.episodeUuid)"
            )

            let data = await FingerprintReferenceRetriever.shared.fetchReferenceData(
                podcastUuid: request.podcastUuid,
                episodeUuid: request.episodeUuid
            )
            guard !Task.isCancelled else { return }
            if let data {
                await Self.saveReference(data, toPath: request.referenceFilePath, episodeUuid: request.episodeUuid)
                loaded = await Self.decodeReference(data)
            }
        }

        guard let loaded else {
            state = .unavailable
            track(.syncedTranscriptsUnavailable, properties: ["reason": "no_reference"])
            FileLog.shared.addMessage(
                "FingerprintTimingManager: no reference available for \(request.episodeUuid)"
            )
            return
        }

        await configure(reference: loaded, request: request)
    }

    private func configure(reference: DecodedReference, request: EpisodeRequest) async {
        guard request.duration > 0 else {
            state = .unavailable
            track(.syncedTranscriptsUnavailable, properties: ["reason": "invalid_duration"])
            return
        }

        let processor = FingerprintStreamProcessor()
        let checkpointCount = await processor.prepare(
            reference: reference.fingerprint,
            episodeUuid: request.episodeUuid,
            audioDuration: request.duration
        )
        guard !Task.isCancelled else { return }
        guard let checkpointCount else {
            state = .unavailable
            track(.syncedTranscriptsUnavailable, properties: ["reason": "no_reference"])
            FileLog.shared.addMessage(
                "FingerprintTimingManager: reference for \(request.episodeUuid) has no usable checkpoints"
            )
            return
        }

        streamProcessor = processor
        let ctx = GenerationContext(
            request: request,
            referenceData: reference.data,
            referenceDuration: reference.fingerprint.totalDuration
        )
        context = ctx

        if preparationStartDate == nil {
            preparationStartDate = Date()
        }
        state = .preparing
        if !hasEmittedPreparationStarted {
            track(.syncedTranscriptsPreparationStarted, properties: [
                "is_streaming": request.isStreaming,
                "episode_duration_seconds": request.duration
            ])
            hasEmittedPreparationStarted = true
        }
        FileLog.shared.addMessage(
            "FingerprintTimingManager: preparing for \(request.episodeUuid) (\(checkpointCount) checkpoints)"
        )

        // All-or-nothing cache: only short-circuit the stream if a previous
        // session persisted a mapping that covers the whole reference timeline
        // for this exact audio file + reference. Partial caches are ignored
        // (the failed branch's `inRange` short-circuit on partial coverage was
        // what trapped the manager in `.preparing`).
        let cached = request.isStreaming ? nil : await Self.loadCachedSnapshot(
            audioFilePath: request.audioFileURL.path,
            referenceFilePath: request.referenceFilePath,
            referenceData: reference.data
        )
        guard !Task.isCancelled else { return }

        // Capture once so the range check, log, and stream start all use the same position.
        let currentTime = PlaybackManager.shared.currentTime()

        if let cached {
            main.snapshot = cached

            if isWithinMappedRange(currentTime) {
                main.filterLastTrusted = cached.playbackToReference.last
                let coverage = cached.playbackToReference.count
                state = .active(coverage: coverage)
                if !hasReachedActive {
                    hasReachedActive = true
                    track(.syncedTranscriptsPreparationCompleted, properties: [
                        "duration_ms": preparationDurationMs,
                        "is_streaming": request.isStreaming
                    ])
                }
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: skipping stream — full mapping loaded from cache for \(request.episodeUuid)"
                )
                return
            }

            FileLog.shared.addMessage(
                "FingerprintTimingManager: cache loaded for \(request.episodeUuid) but playback at "
                    + "\(String(format: "%.1f", currentTime))s is outside cached range — starting stream"
            )
        }

        startStream(context: ctx, fromPosition: currentTime)
    }

    // MARK: - Streaming Fingerprint Processing

    private func startStream(context ctx: GenerationContext, fromPosition position: Double) {
        guard let processor = streamProcessor else { return }
        streamTask?.cancel()

        let aligned = Self.alignToWindowGrid(position)
        let request = ctx.request
        let referenceData = ctx.referenceData
        let referenceDuration = ctx.referenceDuration
        let currentPlaybackTime: @Sendable () async -> Double = {
            await MainActor.run { PlaybackManager.shared.currentTime() }
        }
        let commit: @Sendable (MatchBatch) async -> Void = { [weak self] batch in
            await self?.commit(batch, for: request)
        }

        streamTask = Task(priority: .utility) { [weak self] in
            do {
                try await processor.run(
                    audioFileURL: request.audioFileURL,
                    isStreaming: request.isStreaming,
                    startingAt: aligned,
                    currentPlaybackTime: currentPlaybackTime,
                    commit: commit
                )
                #if DEBUG
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming fingerprint completed (started at \(String(format: "%.1f", aligned))s)"
                )
                #endif
                guard let self else { return }
                // Only persist a mapping for a complete local file, and only when
                // it covers the whole reference timeline — `FingerprintMappingCache`
                // enforces the same threshold the load path requires.
                if !request.isStreaming, self.context?.request.episodeUuid == request.episodeUuid {
                    await Self.persistMappingCache(
                        self.main.snapshot.playbackToReference,
                        request: request,
                        referenceData: referenceData,
                        referenceDuration: referenceDuration
                    )
                }
                self.finishIfStillPreparing(terminalState: .unavailable, context: ctx)
            } catch is CancellationError {
                #if DEBUG
                FileLog.shared.addMessage("FingerprintTimingManager: streaming fingerprint cancelled")
                #endif
                // State will be reset by whatever cancelled us (restart / stop / new episode).
            } catch {
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming fingerprint failed — \(error.localizedDescription)"
                )
                self?.finishIfStillPreparing(terminalState: .failed(error), context: ctx)
            }
        }
    }

    /// Fold a batch of scored candidates into the committed mapping: the drift
    /// filter, two sorted inserts, and a coverage check.
    private func commit(_ batch: MatchBatch, for request: EpisodeRequest) {
        // A batch already in flight when the run was cancelled still lands here.
        // Drop it unless it belongs to the episode we're currently mapping.
        guard context?.request.episodeUuid == request.episodeUuid else { return }

        #if DEBUG
        for rejection in batch.rejections {
            main.record(rejection.entry, reason: rejection.reason)
        }
        #endif
        for candidate in batch.candidates {
            main.consider(candidate)
        }

        let coverage = main.snapshot.playbackToReference.count
        guard coverage >= FingerprintConstants.minimumCoverageForActive else { return }
        state = .active(coverage: coverage)
        if !hasReachedActive {
            hasReachedActive = true
            track(.syncedTranscriptsPreparationCompleted, properties: [
                "duration_ms": preparationDurationMs,
                "is_streaming": request.isStreaming
            ])
        }
    }

    /// Only override state if the stream for `ctx` is still the current one AND we
    /// haven't already reached `.active` — otherwise a late completion for an
    /// abandoned context would clobber a healthy state.
    private func finishIfStillPreparing(terminalState: State, context ctx: GenerationContext) {
        guard context?.request.episodeUuid == ctx.request.episodeUuid else { return }
        if case .active = state { return }

        state = terminalState
        switch terminalState {
        case .failed(let error):
            let nsError = error as NSError
            track(.syncedTranscriptsPreparationFailed, properties: [
                "error_code": nsError.code,
                "error_domain": nsError.domain,
                "stage": "fingerprint_generation",
                "duration_ms": preparationDurationMs
            ])
        case .unavailable:
            track(.syncedTranscriptsUnavailable, properties: [
                "reason": ctx.request.isStreaming ? "streaming_unsupported" : "no_matches",
                "is_streaming": ctx.request.isStreaming
            ])
        default:
            break
        }
    }

    // MARK: - Static Helpers

    /// Snap a playback time to the window-interval grid so emitted window
    /// timestamps are deterministic (stable across restarts and cache reuse).
    /// Windows are emitted every `windowIntervalMs`, finer than the reference's
    /// 2s checkpoint grid, so a correctly-phased window exists for any dynamic-ad
    /// offset rather than relying on a single phase happening to line up.
    nonisolated private static func alignToWindowGrid(_ time: Double) -> Double {
        let stride = Double(FingerprintConstants.windowIntervalMs) / 1000.0
        guard stride > 0 else { return max(0, time) }
        return max(0, floor(time / stride) * stride)
    }

    nonisolated private static func elapsedMs(since date: Date) -> Int {
        Int(Date().timeIntervalSince(date) * 1000)
    }

    /// Bounded region of local audio to fingerprint when resolving a chapter's
    /// reference time to a playback position. Dynamic-ad offset is non-negative
    /// and non-decreasing, so the true playback position is never below
    /// `referenceTime` — the window always starts at or after it.
    ///
    /// - Warm (`estimatedPlayback` from an existing mapping): center on the
    ///   estimate, allowing it to be earlier (a smaller offset earlier in the
    ///   episode) by up to `onDemandSeekBackwardMaxSeconds` and later (more
    ///   intervening ads) by up to `onDemandSeekForwardBudgetSeconds`.
    /// - Cold (no mapping — the common case): search forward from the raw
    ///   reference time up to `onDemandSeekColdBudgetSeconds`.
    nonisolated static func searchWindow(referenceTime: Double, estimatedPlayback: Double?) -> (start: Double, end: Double) {
        if let estimate = estimatedPlayback {
            let start = max(referenceTime, estimate - FingerprintConstants.onDemandSeekBackwardMaxSeconds)
            let end = max(start, estimate + FingerprintConstants.onDemandSeekForwardBudgetSeconds)
            return (start, end)
        }
        return (referenceTime, referenceTime + FingerprintConstants.onDemandSeekColdBudgetSeconds)
    }

    nonisolated static func interpolate(
        time: Double,
        in entries: [TimeMappingEntry],
        keyPath: KeyPath<TimeMappingEntry, Double>,
        valuePath: KeyPath<TimeMappingEntry, Double>
    ) -> Double? {
        guard !entries.isEmpty else { return nil }

        let last = entries.count - 1

        if time <= entries[0][keyPath: keyPath] {
            let offset = time - entries[0][keyPath: keyPath]
            return entries[0][keyPath: valuePath] + offset
        }

        if time >= entries[last][keyPath: keyPath] {
            let offset = time - entries[last][keyPath: keyPath]
            return entries[last][keyPath: valuePath] + offset
        }

        var lo = 0
        var hi = last
        while lo < hi - 1 {
            let mid = (lo + hi) / 2
            if entries[mid][keyPath: keyPath] <= time {
                lo = mid
            } else {
                hi = mid
            }
        }

        let t0 = entries[lo][keyPath: keyPath]
        let t1 = entries[hi][keyPath: keyPath]
        let v0 = entries[lo][keyPath: valuePath]
        let v1 = entries[hi][keyPath: valuePath]

        let fraction = (t1 > t0) ? (time - t0) / (t1 - t0) : 0
        return v0 + fraction * (v1 - v0)
    }

    /// Whether `playbackTime` is bracketed by two committed anchors no further
    /// apart than `highlightMaxGapSeconds`. See `isWithinMatchedContent(forPlaybackTime:)`.
    nonisolated static func isWithinMatchedContent(
        forPlaybackTime playbackTime: Double,
        in entries: [TimeMappingEntry]
    ) -> Bool {
        // Binary search for the anchors bracketing `playbackTime`. `hi` is the
        // first anchor strictly after it; `hi - 1` the last at or before it.
        var lo = 0
        var hi = entries.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if entries[mid].playbackTime <= playbackTime {
                lo = mid + 1
            } else {
                hi = mid
            }
        }

        // Need a committed anchor on each side: before the first or past the last
        // we aren't confidently on matched content, so don't highlight.
        guard hi - 1 >= 0, hi < entries.count else { return false }

        let gap = entries[hi].playbackTime - entries[hi - 1].playbackTime
        return gap <= FingerprintConstants.highlightMaxGapSeconds
    }

    /// Runs `operation`, cancelling it and returning nil if it hasn't finished
    /// within `seconds`.
    nonisolated private static func withTimeout<T: Sendable>(
        _ seconds: TimeInterval,
        _ operation: @escaping @Sendable () async -> T
    ) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try? await Task.sleep(for: .seconds(seconds))
                return nil
            }
            // One level of optionality is the group's "no children left", the
            // other is the timeout child reporting that it won.
            guard let first = await group.next() else { return nil }
            group.cancelAll()
            return first
        }
    }

    // MARK: - Episode / Reference Helpers

    /// A decoded reference plus the bytes it came from — the cache validates
    /// against the raw bytes, so both travel together.
    private struct DecodedReference: Sendable {
        let data: Data
        let fingerprint: ReferenceFingerprint
    }

    /// Captures everything the fingerprint run needs from `episode`.
    nonisolated static func makeRequest(for episode: BaseEpisode) -> EpisodeRequest {
        let downloadPath = DownloadManager.shared.pathForEpisode(episode)
        let source = audioSource(for: episode, downloadPath: downloadPath)
        return EpisodeRequest(
            episodeUuid: episode.uuid,
            podcastUuid: episode.parentIdentifier(),
            duration: episode.duration,
            audioFileURL: source.url,
            isStreaming: source.isStreaming,
            referenceFilePath: (downloadPath as NSString).deletingPathExtension + ".ref.fp.json"
        )
    }

    /// Which local file backs the fingerprint loop for this episode.
    ///
    /// - A complete file (downloaded, or fully stream-cached) reads to EOF.
    /// - A streaming buffer may be absent at call time or still growing, so the
    ///   grow-loop waits for it to appear and polls for new bytes.
    nonisolated private static func audioSource(
        for episode: BaseEpisode,
        downloadPath: String
    ) -> (url: URL, isStreaming: Bool) {
        if FileManager.default.fileExists(atPath: downloadPath) {
            return (URL(fileURLWithPath: downloadPath), false)
        }
        // A stream-downloaded episode keeps a complete file at the streaming
        // buffer path. It isn't growing, so route it through the one-shot
        // fingerprint path instead of the grow-loop.
        if let episode = episode as? Episode,
           episode.streamDownloaded(pathFinder: DownloadManager.shared) {
            let streamingPath = DownloadManager.shared.streamingBufferPathForEpisode(episode)
            if FileManager.default.fileExists(atPath: streamingPath) {
                return (URL(fileURLWithPath: streamingPath), false)
            }
        }
        // Active streaming: the file is either absent or still growing.
        // `MediaExporterResourceLoaderDelegate` (stream-and-cache, default on)
        // writes to `tempPathForEpisode`, while the legacy URLSession path writes
        // to `streamingBufferPathForEpisode`. Prefer whichever file already
        // exists; otherwise pick the one the active feature flag selects.
        let tempPath = DownloadManager.shared.tempPathForEpisode(episode)
        let streamingPath = DownloadManager.shared.streamingBufferPathForEpisode(episode)
        if FileManager.default.fileExists(atPath: tempPath) {
            return (URL(fileURLWithPath: tempPath), true)
        }
        if FileManager.default.fileExists(atPath: streamingPath) {
            return (URL(fileURLWithPath: streamingPath), true)
        }
        let preferred = FeatureFlag.streamAndCachePlayingEpisode.enabled ? tempPath : streamingPath
        return (URL(fileURLWithPath: preferred), true)
    }

    /// Reference resolution shared by both one-shot resolves: warm context →
    /// disk → server.
    nonisolated private func resolveReference(for request: EpisodeRequest, warm: Data?) async -> DecodedReference? {
        if let warm, let decoded = await Self.decodeReference(warm) { return decoded }
        if let onDisk = await Self.loadReference(atPath: request.referenceFilePath) { return onDisk }

        guard let data = await FingerprintReferenceRetriever.shared.fetchReferenceData(
            podcastUuid: request.podcastUuid,
            episodeUuid: request.episodeUuid
        ) else { return nil }

        await Self.saveReference(data, toPath: request.referenceFilePath, episodeUuid: request.episodeUuid)
        return await Self.decodeReference(data)
    }

    nonisolated private static func loadReference(atPath path: String) async -> DecodedReference? {
        guard let data = FileManager.default.contents(atPath: path),
              let fingerprint = ReferenceFingerprint.decode(from: data) else { return nil }
        return DecodedReference(data: data, fingerprint: fingerprint)
    }

    nonisolated private static func decodeReference(_ data: Data) async -> DecodedReference? {
        guard let fingerprint = ReferenceFingerprint.decode(from: data) else { return nil }
        return DecodedReference(data: data, fingerprint: fingerprint)
    }

    nonisolated private static func saveReference(_ data: Data, toPath path: String, episodeUuid: String) async {
        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            FileLog.shared.addMessage("FingerprintTimingManager: saved reference to disk for \(episodeUuid)")
        } catch {
            FileLog.shared.addMessage("FingerprintTimingManager: failed to save reference — \(error.localizedDescription)")
        }
    }

    nonisolated private static func loadCachedSnapshot(
        audioFilePath: String,
        referenceFilePath: String,
        referenceData: Data
    ) async -> MappingSnapshot? {
        guard let cached = FingerprintMappingCache.load(
            audioFilePath: audioFilePath,
            referenceFilePath: referenceFilePath,
            referenceData: referenceData
        ) else { return nil }
        // The cache is produced from `playbackToReference` (already sorted by
        // `playbackTime`), so assign it directly and sort once for the
        // reference-keyed view — avoids the O(n²) cost of routing every entry
        // through `MappingSnapshot.insert`'s per-entry `Array.insert`.
        return MappingSnapshot(
            playbackToReference: cached.entries,
            referenceToPlayback: cached.entries.sorted { $0.referenceTime < $1.referenceTime }
        )
    }

    nonisolated private static func persistMappingCache(
        _ entries: [TimeMappingEntry],
        request: EpisodeRequest,
        referenceData: Data,
        referenceDuration: Double
    ) async {
        FingerprintMappingCache.save(
            entries,
            audioFilePath: request.audioFileURL.path,
            referenceFilePath: request.referenceFilePath,
            referenceData: referenceData,
            referenceDuration: referenceDuration
        )
    }

    // MARK: - Test Seams

    /// Inserts a mapping directly, the way a committed match would.
    func insert(mapping: TimeMappingEntry) {
        main.snapshot.insert(mapping)
    }

    /// Routes a sequence of candidates through the drift filter, the way
    /// `commit` does in production.
    func stubMatches(_ entries: [TimeMappingEntry]) {
        for entry in entries {
            main.consider(entry)
        }
    }
}
