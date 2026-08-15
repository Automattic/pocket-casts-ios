import AVFoundation
import Accelerate
import Foundation
import Fingerprint
import PocketCastsDataModel
import PocketCastsUtils
import os

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

    // MARK: - Singleton

    static let shared = FingerprintTimingManager()

    // MARK: - Public Properties

    private(set) var state: State = .idle

    // MARK: - Internal Types

    private struct GenerationContext {
        /// Identifies one stream run. A restart builds a fresh context for the
        /// same episode, so work in flight has to be matched against this rather
        /// than against `episodeUuid` to be recognised as stale.
        let generation: Int
        let episodeUuid: String
        let audioFileURL: URL
        /// True when `audioFileURL` points at a streaming buffer that may still be
        /// growing. The fingerprint loop polls for new bytes instead of quitting
        /// at EOF.
        let isStreaming: Bool
        let duration: Double
        let matcher: CheckpointMatcher
        /// Raw bytes of the reference fingerprint JSON, used to validate the
        /// persistent mapping cache via SHA-256.
        let referenceData: Data
        /// On-disk path of the reference fingerprint file, used to validate
        /// the persistent mapping cache via file identity (size+mtime).
        let referenceFilePath: String
        /// Total duration of the reference timeline, used to gate the persistent
        /// mapping cache on full coverage.
        let referenceDuration: Double
        let isCancelled: () -> Bool
    }

    struct TimeMappingEntry {
        let playbackTime: Double
        let referenceTime: Double
        let score: Float

        init(playbackTime: Double, referenceTime: Double, score: Float = 0) {
            self.playbackTime = playbackTime
            self.referenceTime = referenceTime
            self.score = score
        }
    }

    /// The mutable state a fingerprint match run accumulates: the two sorted
    /// mapping views, the drift filter's rolling state, and the DEBUG rejection
    /// log. Extracted into a value type so the continuous transcript path
    /// (`main`) and the one-shot resolves can each run the identical matching
    /// pipeline against their own isolated accumulator, without the one-shots
    /// ever touching the mapping the highlighter depends on.
    ///
    /// This is the *complete* mutable state of a match run: `matchWindows` and
    /// everything below it are static and read nothing else, so a caller holding
    /// exclusive access to its own accumulator needs no further synchronization.
    struct MappingAccumulator {
        var playbackToReference: [TimeMappingEntry] = []
        var referenceToPlayback: [TimeMappingEntry] = []
        var filterLastTrusted: TimeMappingEntry?
        var filterCandidatePool: [TimeMappingEntry] = []
        #if DEBUG
        /// Candidates the drift filter rejected, capped at `debugRejectionCap`.
        /// Lives here rather than on the manager so the whole match pipeline is a
        /// pure function of its accumulator — see `matchWindows`.
        var rejections: [TimeMappingEntry] = []
        #endif
    }

    // MARK: - Private State

    private let queue = DispatchQueue(label: "au.com.pocketcasts.FingerprintTimingManager")
    private let generationQueue = DispatchQueue(
        label: "au.com.pocketcasts.FingerprintTimingManager.generation",
        qos: .utility
    )
    /// Decode queue reserved for the one-shot resolves, chapter and bookmark alike.
    /// Kept separate from `generationQueue` — which the continuous transcript stream
    /// occupies as one long-running block that only yields via `Thread.sleep` — so a
    /// bounded decode can't be starved behind it (which would hang the resolve past
    /// its timeout, since a queued-but-never-started block can't observe
    /// cancellation). Higher QoS because a spinner is blocked on it.
    ///
    /// The two one-shots share it because both are bounded, which is the distinction
    /// that matters here. A bookmark resolve's long budget is spent waiting for its
    /// buffer, not on this queue, so its decode is no longer than a chapter's; and
    /// running them concurrently would only make them contend for CPU.
    private let onDemandQueue = DispatchQueue(
        label: "au.com.pocketcasts.FingerprintTimingManager.onDemand",
        qos: .userInitiated
    )
    private var context: GenerationContext?
    /// Source of `GenerationContext.generation`. Only touched on `queue`, where
    /// every context is built.
    private var lastGeneration = 0
    private var cancellationFlag = CancellationFlag()
    private var fetchTask: Task<Void, Never>?

    /// Cancellation + task handles for the one-shot chapter resolve. Kept
    /// separate from the continuous `cancellationFlag`/`fetchTask` so a chapter
    /// tap never cancels (or is cancelled by) transcript preparation. Accessed
    /// only from the main queue, where `resolvePlaybackTime` is invoked.
    private var onDemandFlag = CancellationFlag()
    private var onDemandTask: Task<Void, Never>?

    /// Accumulator backing the continuous transcript mapping (playback↔reference
    /// plus drift-filter state). The one-shot chapter resolve uses its own local
    /// accumulator and never mutates this one — see `resolvePlaybackTime`.
    private var main = MappingAccumulator()

    private var lastProgressPosition: Double = -1

    private var preparationStartDate: Date?
    private var hasReachedActive = false
    private var hasEmittedPreparationStarted = false

    #if DEBUG
    private static let debugRejectionCap = 500
    #endif

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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    func prepareForCurrentEpisode() {
        let episode = PlaybackManager.shared.currentEpisode

        queue.async { [weak self] in
            guard let self else { return }
            self.resetState()
            self.prepareForEpisode(episode)
        }
    }

    /// Cancel any in-flight reference fetch and streaming fingerprint work, discard
    /// the current context and mappings, and return to `.idle`. Called when the
    /// transcript view is torn down so we don't keep burning CPU/memory on audio
    /// the listener is no longer looking at.
    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.resetState()
            self.updateState(.idle)
            FileLog.shared.addMessage("FingerprintTimingManager: stopped")
        }
    }

    /// When an episode download completes while the transcript flow has already requested
    /// preparation, retry. If we previously gave up because no local file existed, or were
    /// processing a partial streaming buffer, we now have a complete file to fingerprint.
    @objc private func handleEpisodeDownloaded(_ notification: Notification) {
        guard let downloadedUuid = notification.object as? String,
              let currentUuid = PlaybackManager.shared.currentEpisode?.uuid,
              currentUuid == downloadedUuid else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if case .active = self.state { return }
            FileLog.shared.addMessage(
                "FingerprintTimingManager: episode \(downloadedUuid) finished downloading — re-preparing"
            )
            self.prepareForCurrentEpisode()
        }
    }

    /// Re-anchor fingerprint generation to wherever the listener is now: if playback
    /// jumps suddenly (seek/skip), or drifts beyond the mapped range, restart the
    /// stream from the new position so coverage stays close to what's playing.
    @objc private func handlePlaybackProgress() {
        let playbackTime = PlaybackManager.shared.currentTime()
        guard playbackTime >= 0 else { return }

        let episodeUuid = PlaybackManager.shared.currentEpisode?.uuid
        queue.async { [weak self] in
            self?.processProgress(playbackTime: playbackTime, episodeUuid: episodeUuid)
        }
    }

    private func processProgress(playbackTime: Double, episodeUuid: String?) {
        guard let ctx = context, ctx.episodeUuid == episodeUuid else { return }

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
        if main.playbackToReference.isEmpty { return }

        #if DEBUG
        FileLog.shared.addMessage(
            "FingerprintTimingManager: playback at \(String(format: "%.1f", playbackTime))s outside mapped range — restarting"
        )
        #endif
        restart(from: playbackTime, context: ctx)
    }

    private func isWithinMappedRange(_ playbackTime: Double) -> Bool {
        guard let first = main.playbackToReference.first,
              let last = main.playbackToReference.last else { return false }
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
        cancellationFlag.cancel()
        cancellationFlag = CancellationFlag()
        let flag = cancellationFlag
        let newContext = GenerationContext(
            generation: nextGeneration(),
            episodeUuid: ctx.episodeUuid,
            audioFileURL: ctx.audioFileURL,
            isStreaming: ctx.isStreaming,
            duration: ctx.duration,
            matcher: ctx.matcher,
            referenceData: ctx.referenceData,
            referenceFilePath: ctx.referenceFilePath,
            referenceDuration: ctx.referenceDuration,
            isCancelled: { flag.isCancelled }
        )
        context = newContext
        resetFilterState()
        startStream(context: newContext, fromPosition: position)
    }

    func referenceTime(forPlaybackTime playbackTime: Double) -> Double? {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync {
            Self.interpolate(
                time: playbackTime,
                in: main.playbackToReference,
                keyPath: \.playbackTime,
                valuePath: \.referenceTime
            )
        }
    }

    func playbackTime(forReferenceTime referenceTime: Double) -> Double? {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync {
            Self.interpolate(
                time: referenceTime,
                in: main.referenceToPlayback,
                keyPath: \.referenceTime,
                valuePath: \.playbackTime
            )
        }
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
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync {
            Self.isWithinMatchedContent(forPlaybackTime: playbackTime, in: main.playbackToReference)
        }
    }

    /// The reference time for `playbackTime`, but only when it's on matched content
    /// (see `isWithinMatchedContent`). Combines the gate and the interpolation into
    /// a single `queue.sync` so the highlight tick — driven by the display link at
    /// ~60Hz — pays one lock per frame and can't see the two disagree if the mapping
    /// mutates between them.
    func matchedReferenceTime(forPlaybackTime playbackTime: Double) -> Double? {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync {
            guard Self.isWithinMatchedContent(forPlaybackTime: playbackTime, in: main.playbackToReference) else {
                return nil
            }
            return Self.interpolate(
                time: playbackTime,
                in: main.playbackToReference,
                keyPath: \.playbackTime,
                valuePath: \.referenceTime
            )
        }
    }

    // MARK: - On-demand chapter seek

    /// Outcome of a one-shot chapter resolve. `reason` on `.unresolved` is a
    /// stable analytics token the caller reports and can key fallback behavior on.
    enum ChapterSeekResult {
        case resolved(playbackTime: Double, usedPrior: Bool, isStreaming: Bool, resolveDurationMs: Int)
        case unresolved(reason: String, isStreaming: Bool)
    }

    /// Resolve a generated chapter's reference-timeline `referenceTime` to the
    /// playback-timeline position where that content actually occurs in the
    /// listener's audio (which dynamic ads have shifted), by fingerprinting a
    /// bounded region of the local file around the expected area and matching it
    /// against the reference.
    ///
    /// This is a one-shot, side-effect-free operation: it uses its own reference
    /// data, matcher, cancellation flag, and a local scratch mapping, and never
    /// mutates the continuous transcript mapping (`main`), `context`, or `state`.
    /// A second call supersedes any still-running one (last tap wins).
    ///
    /// Must be called on the main queue. `completion` is delivered on the main
    /// queue; a superseded resolve never calls back.
    func resolvePlaybackTime(
        forReferenceTime referenceTime: Double,
        episode: BaseEpisode,
        completion: @escaping (ChapterSeekResult) -> Void
    ) {
        dispatchPrecondition(condition: .onQueue(.main))
        // Supersede any prior in-flight resolve.
        onDemandFlag.cancel()
        let flag = CancellationFlag()
        onDemandFlag = flag
        onDemandTask?.cancel()

        onDemandTask = Task { [weak self] in
            guard let self else { return }

            // Hard timeout: cancel the flag after the deadline so a slow decode
            // can't leave the tap spinning indefinitely. The decode loop observes
            // the flag once per chunk.
            let timeoutTask = Task {
                try? await Task.sleep(
                    nanoseconds: UInt64(FingerprintConstants.onDemandSeekTimeoutSeconds * 1_000_000_000)
                )
                flag.cancel()
            }
            defer { timeoutTask.cancel() }

            let result = await self.performResolve(
                forReferenceTime: referenceTime,
                episode: episode,
                kind: .chapter,
                flag: flag
            )

            await MainActor.run {
                // Drop the result if a newer resolve superseded us (last tap wins).
                guard self.onDemandFlag === flag else { return }
                completion(result)
            }
        }
    }

    /// Resolve a bookmark's reference-timeline position to where that content
    /// actually sits in this listener's audio, so playback can start there.
    ///
    /// The same one-shot resolve as `resolvePlaybackTime`, differing only in what a
    /// bookmark's audio is likely to be doing — see `ResolveKind.bookmark`. It keeps
    /// no state of its own, so it neither supersedes nor is superseded by a chapter
    /// resolve; the caller owns the lifetime, and cancelling its task stops the
    /// decode via the cancellation handler below.
    func resolveBookmarkPlaybackTime(
        forReferenceTime referenceTime: Double,
        episode: BaseEpisode
    ) async -> ChapterSeekResult {
        dispatchPrecondition(condition: .notOnQueue(queue))
        let flag = CancellationFlag()

        // Hard timeout, so a decode that drags or a buffer that never arrives can't
        // leave the correction pending forever. Both loops observe the flag.
        let timeoutTask = Task {
            try? await Task.sleep(
                nanoseconds: UInt64(FingerprintConstants.bookmarkSeekTimeoutSeconds * 1_000_000_000)
            )
            flag.cancel()
        }
        defer { timeoutTask.cancel() }

        return await withTaskCancellationHandler {
            await performResolve(
                forReferenceTime: referenceTime,
                episode: episode,
                kind: .bookmark,
                flag: flag
            )
        } onCancel: {
            flag.cancel()
        }
    }

    /// Cancel any in-flight one-shot chapter resolve without delivering a result.
    /// Called on view teardown so a backgrounded chapters list can't seek later.
    ///
    /// Swapping in a fresh `onDemandFlag` supersedes the running task the same way
    /// a newer resolve would: even if it finishes, its `onDemandFlag === flag`
    /// guard now fails, so its completion (and any fallback seek) is dropped.
    func cancelPendingChapterResolve() {
        dispatchPrecondition(condition: .onQueue(.main))
        onDemandFlag.cancel()
        onDemandFlag = CancellationFlag()
        onDemandTask?.cancel()
        onDemandTask = nil
    }

    /// What the two one-shot resolves want differently, which all follows from what
    /// their audio is likely to be doing: a chapter's episode is playing, so its
    /// audio is already local, while a bookmark's is often still downloading.
    private enum ResolveKind {
        case chapter
        case bookmark

        /// Only a bookmark waits for the streaming buffer to reach the search window.
        var waitsForBufferedRegion: Bool { self == .bookmark }
    }

    private func performResolve(
        forReferenceTime referenceTime: Double,
        episode: BaseEpisode,
        kind: ResolveKind,
        flag: CancellationFlag
    ) async -> ChapterSeekResult {
        let startDate = Date()
        let episodeUuid = episode.uuid

        // Snapshot the warm prior (if the transcript flow already has a mapping
        // for this episode) read-only on `queue`: its reference data lets us skip
        // disk/network, and the existing mapping estimates the ad offset at the
        // target so we can tighten the search window.
        let prior: (referenceData: Data?, estimatedPlayback: Double?) = queue.sync {
            guard let ctx = context, ctx.episodeUuid == episodeUuid else { return (nil, nil) }
            let estimate = Self.interpolate(
                time: referenceTime,
                in: main.referenceToPlayback,
                keyPath: \.referenceTime,
                valuePath: \.playbackTime
            )
            return (ctx.referenceData, estimate)
        }

        // Resolve reference data: warm context → disk → server.
        var referenceData = prior.referenceData ?? loadReference(for: episode)?.data
        if referenceData == nil {
            referenceData = await FingerprintReferenceRetriever.shared.fetchReferenceData(
                podcastUuid: episode.parentIdentifier(),
                episodeUuid: episodeUuid
            )
            if let referenceData { saveReferenceData(referenceData, for: episode) }
        }

        if flag.isCancelled { return .unresolved(reason: "timeout", isStreaming: false) }
        guard let referenceData,
              let reference = ReferenceFingerprint.decode(from: referenceData) else {
            return .unresolved(reason: "no_reference", isStreaming: false)
        }

        let duration = episode.duration
        guard duration > 0,
              let (matcher, _) = buildMatcher(from: reference, episodeUuid: episodeUuid, audioDuration: duration) else {
            return .unresolved(reason: "no_reference", isStreaming: false)
        }

        let usedPrior = prior.estimatedPlayback != nil
        let window = Self.searchWindow(
            referenceTime: referenceTime,
            estimatedPlayback: prior.estimatedPlayback
        )
        let alignedStart = Self.alignToWindowGrid(window.start)
        let searchEnd = window.end

        let source = resolveAudioSource(for: episode)
        let audioURL: URL
        let isStreaming: Bool
        switch source {
        case .downloaded(let url): audioURL = url; isStreaming = false
        case .streaming(let url): audioURL = url; isStreaming = true
        }

        // A bookmark's episode is often still arriving: playing it starts a
        // stream-and-cache download that fills the buffer sequentially from byte 0,
        // so the window we want only becomes readable once that prefix reaches it.
        if kind.waitsForBufferedRegion, isStreaming {
            await waitForBufferedRegion(
                audioFileURL: audioURL,
                coveringSeconds: searchEnd,
                deadline: startDate.addingTimeInterval(FingerprintConstants.bookmarkSeekBufferWaitSeconds),
                flag: flag
            )
        }

        if flag.isCancelled { return .unresolved(reason: "timeout", isStreaming: isStreaming) }

        // Fingerprint + match the bounded region into a local scratch accumulator
        // on `onDemandQueue` (heavy decode, dedicated so the continuous stream on
        // `generationQueue` can't starve it) — `main` is never touched.
        let outcome: Result<MappingAccumulator, StreamError> = await withCheckedContinuation { continuation in
            onDemandQueue.async {
                var scratch = MappingAccumulator()
                do {
                    try self.streamFingerprintBounded(
                        audioFileURL: audioURL,
                        startSeconds: alignedStart,
                        endSeconds: searchEnd,
                        matcher: matcher,
                        flag: flag,
                        into: &scratch
                    )
                    continuation.resume(returning: .success(scratch))
                } catch let error as StreamError {
                    continuation.resume(returning: .failure(error))
                } catch {
                    continuation.resume(returning: .failure(.bufferAllocationFailed))
                }
            }
        }

        switch outcome {
        case .failure(.cancelled):
            return .unresolved(reason: "timeout", isStreaming: isStreaming)
        case .failure(.regionUnavailable):
            return .unresolved(reason: "region_not_local", isStreaming: isStreaming)
        case .failure:
            return .unresolved(reason: "no_match", isStreaming: isStreaming)
        case .success(let scratch):
            guard scratch.playbackToReference.count >= FingerprintConstants.onDemandSeekMinAnchors,
                  let playback = Self.interpolate(
                      time: referenceTime,
                      in: scratch.referenceToPlayback,
                      keyPath: \.referenceTime,
                      valuePath: \.playbackTime
                  ) else {
                return .unresolved(reason: "no_match", isStreaming: isStreaming)
            }
            let resolveDurationMs = Int(Date().timeIntervalSince(startDate) * 1000)
            // Comparable across platforms: Android fingerprints eagerly and iOS
            // reactively on tap, but both report the calculation time here, decoupled
            // from `playerChapterSelected` (the tap) which stays untouched.
            Analytics.track(.playerChapterFingerprintCalculated, properties: [
                "duration_ms": resolveDurationMs,
                "is_streaming": isStreaming,
                "episode_uuid": episodeUuid,
                "podcast_uuid": episode.parentIdentifier()
            ])
            return .resolved(
                playbackTime: max(referenceTime, playback),
                usedPrior: usedPrior,
                isStreaming: isStreaming,
                resolveDurationMs: resolveDurationMs
            )
        }
    }

    /// Wait for a still-downloading streaming buffer to cover `coveringSeconds` of
    /// audio, polling as it grows.
    ///
    /// `MediaExporterResourceLoaderDelegate` caches with a single un-ranged request
    /// appended to disk, so the buffer is always a prefix of the episode and
    /// `AVAudioFile.length` tracks exactly how much of it is local — the same
    /// property the grow-loop anchors on.
    ///
    /// Returns once covered, or early when the file stops growing, the deadline
    /// passes, or the resolve is cancelled. There's deliberately no failure signal:
    /// the bounded fingerprint clamps to whatever is readable, so matching a short
    /// prefix of the window still beats returning nothing.
    private func waitForBufferedRegion(
        audioFileURL: URL,
        coveringSeconds: Double,
        deadline: Date,
        flag: CancellationFlag
    ) async {
        let pollCadence = FingerprintConstants.bufferGrowPollCadenceSeconds
        var stallSeconds: Double = 0
        var lastLength: AVAudioFramePosition = -1

        while !flag.isCancelled, Date() < deadline {
            // The buffer may not exist yet, and a partial frame at the tail can make
            // `AVAudioFile` refuse to open momentarily — both read as "no growth".
            if let audioFile = try? AVAudioFile(
                forReading: audioFileURL,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            ) {
                let bufferedSeconds = Double(audioFile.length) / audioFile.processingFormat.sampleRate
                if bufferedSeconds >= coveringSeconds {
                    FileLog.shared.addMessage(
                        "FingerprintTimingManager: streaming buffer covers the search window "
                            + "(\(String(format: "%.1f", bufferedSeconds))s buffered)"
                    )
                    return
                }
                if audioFile.length > lastLength {
                    lastLength = audioFile.length
                    stallSeconds = 0
                }
            }

            stallSeconds += pollCadence
            if stallSeconds >= FingerprintConstants.bookmarkSeekBufferStallSeconds {
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming buffer stopped growing short of the "
                        + "search window — fingerprinting the \(max(0, lastLength)) frames that arrived"
                )
                return
            }
            try? await Task.sleep(nanoseconds: UInt64(pollCadence * 1_000_000_000))
        }
    }

    // MARK: - On-demand bookmark position resolve

    /// Resolves a playback-timeline position (e.g. a bookmark's time) to the
    /// reference timeline, so reference-timed content like a generated
    /// transcript can be read at the right spot despite dynamic-ad shifting.
    ///
    /// Like `resolvePlaybackTime` this is one-shot and side-effect-free: it uses
    /// its own matcher, cancellation flag, and scratch mapping, and never mutates
    /// the continuous transcript mapping (`main`), `context`, or `state`.
    ///
    /// Returns nil when no confident match is found (no reference, audio not
    /// local, timeout) — callers should fall back to the raw playback time.
    func resolveReferenceTime(forPlaybackTime playbackTime: Double, episode: BaseEpisode) async -> Double? {
        dispatchPrecondition(condition: .notOnQueue(queue))
        let episodeUuid = episode.uuid
        let startDate = Date()

        // Warm fast path: interpolate off the continuous transcript mapping when
        // it already confidently covers this position.
        let warm: Double? = queue.sync {
            guard let ctx = context, ctx.episodeUuid == episodeUuid,
                  Self.isWithinMatchedContent(forPlaybackTime: playbackTime, in: main.playbackToReference) else {
                return nil
            }
            return Self.interpolate(
                time: playbackTime,
                in: main.playbackToReference,
                keyPath: \.playbackTime,
                valuePath: \.referenceTime
            )
        }
        if let warm {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: bookmark resolve matched off the live mapping for \(episodeUuid) — "
                    + "local file time \(String(format: "%.1f", playbackTime))s → "
                    + "reference time \(String(format: "%.1f", warm))s"
            )
            return warm
        }

        // Hard timeout, observed once per decoded chunk
        let flag = CancellationFlag()
        let timeoutTask = Task {
            try? await Task.sleep(
                nanoseconds: UInt64(FingerprintConstants.bookmarkResolveTimeoutSeconds * 1_000_000_000)
            )
            flag.cancel()
        }
        defer { timeoutTask.cancel() }

        // Resolve reference data: warm context → disk → server.
        var referenceData: Data? = queue.sync {
            guard let ctx = context, ctx.episodeUuid == episodeUuid else { return nil }
            return ctx.referenceData
        }
        referenceData = referenceData ?? loadReference(for: episode)?.data
        if referenceData == nil {
            referenceData = await FingerprintReferenceRetriever.shared.fetchReferenceData(
                podcastUuid: episode.parentIdentifier(),
                episodeUuid: episodeUuid
            )
            if let referenceData { saveReferenceData(referenceData, for: episode) }
        }

        guard !flag.isCancelled,
              let referenceData,
              let reference = ReferenceFingerprint.decode(from: referenceData) else {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: bookmark resolve gave up for \(episodeUuid) — no usable reference"
            )
            return nil
        }

        let duration = episode.duration
        guard duration > 0,
              let (matcher, _) = buildMatcher(from: reference, episodeUuid: episodeUuid, audioDuration: duration) else {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: bookmark resolve gave up for \(episodeUuid) — no usable checkpoints"
            )
            return nil
        }

        let start = Self.alignToWindowGrid(
            max(0, playbackTime - FingerprintConstants.bookmarkResolveBackwardSeconds)
        )
        let end = playbackTime + FingerprintConstants.bookmarkResolveForwardSeconds

        let audioURL: URL
        switch resolveAudioSource(for: episode) {
        case .downloaded(let url), .streaming(let url):
            audioURL = url
        }

        // Fingerprint + match the bounded region into a local scratch accumulator.
        let scratch: MappingAccumulator? = await withCheckedContinuation { continuation in
            onDemandQueue.async {
                var acc = MappingAccumulator()
                do {
                    try self.streamFingerprintBounded(
                        audioFileURL: audioURL,
                        startSeconds: start,
                        endSeconds: end,
                        matcher: matcher,
                        flag: flag,
                        into: &acc
                    )
                    continuation.resume(returning: acc)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }

        guard let scratch,
              scratch.playbackToReference.count >= FingerprintConstants.bookmarkResolveMinAnchors,
              let referenceTime = Self.interpolate(
                  time: playbackTime,
                  in: scratch.playbackToReference,
                  keyPath: \.playbackTime,
                  valuePath: \.referenceTime
              ) else {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: bookmark resolve found no confident match "
                    + "at local file time \(String(format: "%.1f", playbackTime))s for \(episodeUuid) "
                    + "(\(scratch?.playbackToReference.count ?? 0) anchors, took \(Self.elapsedMs(since: startDate))ms)"
            )
            return nil
        }

        FileLog.shared.addMessage(
            "FingerprintTimingManager: bookmark resolve matched for \(episodeUuid) — "
                + "local file time \(String(format: "%.1f", playbackTime))s → "
                + "reference time \(String(format: "%.1f", referenceTime))s "
                + "(\(scratch.playbackToReference.count) anchors, took \(Self.elapsedMs(since: startDate))ms)"
        )
        return referenceTime
    }

    private static func elapsedMs(since date: Date) -> Int {
        Int(Date().timeIntervalSince(date) * 1000)
    }

    #if DEBUG
    var totalDuration: Double? {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync { context?.duration }
    }

    func debugMappingSnapshot() -> [TimeMappingEntry] {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync { main.playbackToReference }
    }

    /// Candidates that reached the continuous mapping's drift filter but were
    /// rejected. The debug overlay uses this to distinguish "matcher never fired
    /// here" from "matcher fired but everything was filtered out as noise".
    func debugRejectionsSnapshot() -> [TimeMappingEntry] {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync { main.rejections }
    }
    #endif

    // MARK: - State Management

    private func resetState() {
        fetchTask?.cancel()
        fetchTask = nil
        cancellationFlag.cancel()
        cancellationFlag = CancellationFlag()
        context = nil
        main = MappingAccumulator()
        lastProgressPosition = -1
        preparationStartDate = nil
        hasReachedActive = false
        hasEmittedPreparationStarted = false
    }

    private func resetFilterState() {
        main.filterLastTrusted = nil
        main.filterCandidatePool.removeAll()
    }

    private func nextGeneration() -> Int {
        lastGeneration += 1
        return lastGeneration
    }

    private func track(_ event: AnalyticsEvent, properties: [String: Sendable] = [:]) {
        var properties = properties
        if let episodeUuid = context?.episodeUuid {
            properties["episode_uuid"] = episodeUuid
        }
        Analytics.track(event, properties: properties)
    }

    private var preparationDurationMs: Int {
        guard let start = preparationStartDate else { return 0 }
        return Int(Date().timeIntervalSince(start) * 1000)
    }

    private func updateState(_ newState: State) {
        DispatchQueue.main.async { [weak self] in
            self?.state = newState
        }
    }

    // MARK: - Track Preparation

    private func prepareForEpisode(_ episode: BaseEpisode?) {
        updateState(.idle)

        guard FeatureFlag.syncedTranscripts.enabled else {
            updateState(.unavailable)
            track(.syncedTranscriptsUnavailable, properties: ["reason": "feature_disabled"])
            return
        }

        guard let episode else {
            updateState(.unavailable)
            track(.syncedTranscriptsUnavailable, properties: ["reason": "no_episode"])
            return
        }

        let uuid = episode.uuid

        if let loaded = loadReference(for: episode) {
            configureForReference(loaded.reference, referenceData: loaded.data, episode: episode)
            return
        }

        preparationStartDate = Date()
        updateState(.preparing)
        track(.syncedTranscriptsPreparationStarted, properties: [
            "episode_uuid": uuid,
            "episode_duration_seconds": episode.duration
        ])
        hasEmittedPreparationStarted = true
        FileLog.shared.addMessage("FingerprintTimingManager: fetching reference from server for \(uuid)")

        let flag = cancellationFlag
        fetchTask = Task { [weak self] in
            guard !flag.isCancelled else { return }

            let data = await FingerprintReferenceRetriever.shared.fetchReferenceData(
                podcastUuid: episode.parentIdentifier(),
                episodeUuid: uuid
            )

            self?.queue.async { [weak self] in
                guard let self, !flag.isCancelled else { return }

                guard let data, let reference = ReferenceFingerprint.decode(from: data) else {
                    self.updateState(.unavailable)
                    self.track(.syncedTranscriptsUnavailable, properties: ["reason": "no_reference"])
                    FileLog.shared.addMessage("FingerprintTimingManager: no reference available for \(uuid)")
                    return
                }

                self.saveReferenceData(data, for: episode)
                self.configureForReference(reference, referenceData: data, episode: episode)
            }
        }
    }

    private func configureForReference(
        _ reference: ReferenceFingerprint,
        referenceData: Data,
        episode: BaseEpisode
    ) {
        let uuid = episode.uuid

        let source = resolveAudioSource(for: episode)
        let audioFileURL: URL
        let isStreaming: Bool
        switch source {
        case .downloaded(let url):
            audioFileURL = url
            isStreaming = false
        case .streaming(let url):
            audioFileURL = url
            isStreaming = true
        }

        let duration = episode.duration
        guard duration > 0 else {
            updateState(.unavailable)
            track(.syncedTranscriptsUnavailable, properties: ["reason": "invalid_duration"])
            return
        }

        guard let (matcher, checkpointCount) = buildMatcher(
            from: reference,
            episodeUuid: uuid,
            audioDuration: duration
        ) else {
            updateState(.unavailable)
            track(.syncedTranscriptsUnavailable, properties: ["reason": "no_reference"])
            FileLog.shared.addMessage("FingerprintTimingManager: reference for \(uuid) has no usable checkpoints")
            return
        }

        let flag = cancellationFlag
        let refPath = referencePath(for: episode)
        let newContext = GenerationContext(
            generation: nextGeneration(),
            episodeUuid: uuid,
            audioFileURL: audioFileURL,
            isStreaming: isStreaming,
            duration: duration,
            matcher: matcher,
            referenceData: referenceData,
            referenceFilePath: refPath,
            referenceDuration: reference.totalDuration,
            isCancelled: { flag.isCancelled }
        )
        context = newContext

        if preparationStartDate == nil {
            preparationStartDate = Date()
        }
        updateState(.preparing)
        if !hasEmittedPreparationStarted {
            track(.syncedTranscriptsPreparationStarted, properties: [
                "is_streaming": isStreaming,
                "episode_duration_seconds": duration
            ])
            hasEmittedPreparationStarted = true
        }
        FileLog.shared.addMessage(
            "FingerprintTimingManager: preparing for \(uuid) (\(checkpointCount) checkpoints)"
        )

        // Capture once so the range check, log, and stream start all use the same position.
        let currentTime = PlaybackManager.shared.currentTime()

        // All-or-nothing cache: only short-circuit the stream if a previous
        // session persisted a mapping that covers the whole reference timeline
        // for this exact audio file + reference. Partial caches are ignored
        // (the failed branch's `inRange` short-circuit on partial coverage was
        // what trapped the manager in `.preparing`).
        if !isStreaming,
           let cached = FingerprintMappingCache.load(
               audioFilePath: audioFileURL.path,
               referenceFilePath: refPath,
               referenceData: referenceData
           ) {
            // The cache is produced from `playbackToReference` (already sorted
            // by `playbackTime`), so assign it directly and sort once for the
            // reference-keyed view — avoids the O(n²) cost of routing every
            // entry through `insertMapping`'s per-entry `Array.insert`.
            main.playbackToReference = cached.entries
            main.referenceToPlayback = cached.entries.sorted { $0.referenceTime < $1.referenceTime }

            if isWithinMappedRange(currentTime) {
                main.filterLastTrusted = cached.entries.last
                let coverage = cached.entries.count
                updateState(.active(coverage: coverage))
                if !hasReachedActive {
                    hasReachedActive = true
                    track(.syncedTranscriptsPreparationCompleted, properties: [
                        "duration_ms": preparationDurationMs,
                        "is_streaming": isStreaming
                    ])
                }
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: skipping stream — full mapping loaded from cache for \(uuid)"
                )
                return
            }

            FileLog.shared.addMessage(
                "FingerprintTimingManager: cache loaded for \(uuid) but playback at "
                    + "\(String(format: "%.1f", currentTime))s is outside cached range — starting stream"
            )
        }

        startStream(context: newContext, fromPosition: currentTime)
    }

    /// Build a `CheckpointMatcher` populated from every usable checkpoint in
    /// `reference`, plus the decoded checkpoint count. Returns nil when the
    /// reference has no usable checkpoints. Shared by the continuous transcript
    /// path (`configureForReference`) and the one-shot chapter resolve.
    private func buildMatcher(
        from reference: ReferenceFingerprint,
        episodeUuid: String,
        audioDuration: Double
    ) -> (matcher: CheckpointMatcher, checkpointCount: Int)? {
        let duration_s = reference.checkpointDurationSeconds
        let rawCheckpointCount = reference.checkpoints.count
        let libraryCheckpoints = reference.libraryCheckpoints()

        FileLog.shared.addMessage(
            "FingerprintTimingManager: reference for \(episodeUuid) — "
                + "totalDuration=\(reference.totalDuration)s, "
                + "checkpointInterval=\(reference.checkpointInterval), "
                + "checkpointDuration=\(reference.checkpointDuration)s, "
                + "timestampQuantum=\(reference.timestampQuantum), "
                + "raw=\(rawCheckpointCount), decoded=\(libraryCheckpoints.count)"
        )
        if let first = libraryCheckpoints.first, let last = libraryCheckpoints.last {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: checkpoint timestamps span "
                    + "\(String(format: "%.1f", first.timestampSeconds))s..\(String(format: "%.1f", last.timestampSeconds))s "
                    + "(audio duration \(String(format: "%.1f", audioDuration))s)"
            )
        }

        guard !libraryCheckpoints.isEmpty else { return nil }

        let matcher = CheckpointMatcher()
        for checkpoint in libraryCheckpoints {
            matcher.add(
                timestamp: checkpoint.timestampSeconds,
                hashes: checkpoint.hashes,
                duration: duration_s
            )
        }
        return (matcher, libraryCheckpoints.count)
    }

    // MARK: - Streaming Fingerprint Processing

    /// Stream-decode the downloaded file with `AVAudioFile`, push PCM into the
    /// streaming fingerprinter chunk-by-chunk, and match each batch of windows
    /// as soon as it's emitted. We start near the current playback position
    /// (snapped to a 2s grid so window timestamps line up with the reference
    /// checkpoints), so highlighting becomes usable for what the listener is
    /// actually hearing — without waiting for the entire file to be processed.
    private func startStream(context ctx: GenerationContext, fromPosition position: Double) {
        let aligned = Self.alignToWindowGrid(position)
        generationQueue.async { [weak self] in
            guard let self else { return }
            do {
                if ctx.isStreaming {
                    try self.streamFingerprintGrowing(context: ctx, startingAt: aligned)
                } else {
                    try self.streamFingerprint(context: ctx, startingAt: aligned)
                }
                #if DEBUG
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming fingerprint completed (started at \(String(format: "%.1f", aligned))s)"
                )
                #endif
                self.persistMappingCacheIfFull(context: ctx)
                self.finishIfStillPreparing(terminalState: .unavailable, context: ctx)
            } catch StreamError.cancelled {
                #if DEBUG
                FileLog.shared.addMessage("FingerprintTimingManager: streaming fingerprint cancelled")
                #endif
                // State will be reset by whatever cancelled us (restart / stop / new episode).
            } catch {
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming fingerprint failed — \(error.localizedDescription)"
                )
                self.finishIfStillPreparing(terminalState: .failed(error), context: ctx)
            }
        }
    }

    /// Only override state if the stream for `ctx` is still the current one AND we
    /// haven't already reached `.active` — otherwise a late completion for an
    /// abandoned context would clobber a healthy state.
    private func finishIfStillPreparing(terminalState: State, context ctx: GenerationContext) {
        queue.async { [weak self] in
            guard let self, self.context?.generation == ctx.generation else { return }
            let durationMs = self.preparationDurationMs
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if case .active = self.state { return }
                self.state = terminalState
                switch terminalState {
                case .failed(let error):
                    let nsError = error as NSError
                    self.track(.syncedTranscriptsPreparationFailed, properties: [
                        "error_code": nsError.code,
                        "error_domain": nsError.domain,
                        "stage": "fingerprint_generation",
                        "duration_ms": durationMs
                    ])
                case .unavailable:
                    let reason = ctx.isStreaming ? "streaming_unsupported" : "no_matches"
                    self.track(.syncedTranscriptsUnavailable, properties: [
                        "reason": reason,
                        "is_streaming": ctx.isStreaming
                    ])
                default:
                    break
                }
            }
        }
    }

    /// Snap a playback time to the window-interval grid so emitted window
    /// timestamps are deterministic (stable across restarts and cache reuse).
    /// Windows are emitted every `windowIntervalMs`, finer than the reference's
    /// 2s checkpoint grid, so a correctly-phased window exists for any dynamic-ad
    /// offset rather than relying on a single phase happening to line up.
    private static func alignToWindowGrid(_ time: Double) -> Double {
        let stride = Double(FingerprintConstants.windowIntervalMs) / 1000.0
        guard stride > 0 else { return max(0, time) }
        return max(0, floor(time / stride) * stride)
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
    static func searchWindow(referenceTime: Double, estimatedPlayback: Double?) -> (start: Double, end: Double) {
        if let estimate = estimatedPlayback {
            let start = max(referenceTime, estimate - FingerprintConstants.onDemandSeekBackwardMaxSeconds)
            let end = max(start, estimate + FingerprintConstants.onDemandSeekForwardBudgetSeconds)
            return (start, end)
        }
        return (referenceTime, referenceTime + FingerprintConstants.onDemandSeekColdBudgetSeconds)
    }

    private func streamFingerprint(context ctx: GenerationContext, startingAt startSeconds: Double) throws {
        // Force the reader to hand us non-interleaved Float32 PCM so
        // `buffer.floatChannelData` is never nil regardless of the on-disk format.
        let audioFile = try AVAudioFile(
            forReading: ctx.audioFileURL,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let format = audioFile.processingFormat
        let sampleRate = UInt32(format.sampleRate)
        let channels = UInt16(format.channelCount)

        let startFrame = AVAudioFramePosition(startSeconds * format.sampleRate)
        if startFrame > 0, startFrame < audioFile.length {
            audioFile.framePosition = startFrame
        }

        let streamer = StreamingWindowedFingerprinter(
            sampleRate: sampleRate,
            channels: channels,
            windowDurationMs: FingerprintConstants.windowDurationMs,
            windowIntervalMs: FingerprintConstants.windowIntervalMs
        )

        let chunkFrames = AVAudioFrameCount(format.sampleRate * FingerprintConstants.streamChunkSeconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrames) else {
            throw StreamError.bufferAllocationFailed
        }

        var interleaved: [Float] = []
        while true {
            if ctx.isCancelled() { throw StreamError.cancelled }
            let nextChunkStartSeconds = Double(audioFile.framePosition) / format.sampleRate
            try throttleIfBeyondLookahead(nextChunkStartSeconds: nextChunkStartSeconds, context: ctx)
            try audioFile.read(into: buffer, frameCount: chunkFrames)
            if buffer.frameLength == 0 { break }

            Self.interleave(buffer, into: &interleaved)
            let windows = streamer.pushSamplesF32(samples: interleaved, channels: channels)
            if !windows.isEmpty {
                dispatchProcessMatches(windows: windows, startOffset: startSeconds, context: ctx)
            }
        }

        if ctx.isCancelled() { throw StreamError.cancelled }
        let tail = streamer.flush()
        if !tail.isEmpty {
            dispatchProcessMatches(windows: tail, startOffset: startSeconds, context: ctx)
        }
    }

    /// Bounded, one-shot variant of `streamFingerprint` used by the chapter
    /// resolve. Decodes only `[startSeconds, endSeconds]` of `audioFileURL`,
    /// matching each window against `matcher` into `acc`. Unlike the continuous
    /// variant it stops at `endSeconds` (not EOF), skips the lookahead throttle,
    /// and never touches shared manager state — decode and matching both run
    /// inline on the calling `onDemandQueue` against the caller's own `acc`, so
    /// it takes no locks at all. Throws `.regionUnavailable` when the local file
    /// doesn't yet reach `startSeconds` (a streaming episode whose buffer hasn't
    /// advanced to the target chapter).
    private func streamFingerprintBounded(
        audioFileURL: URL,
        startSeconds: Double,
        endSeconds: Double,
        matcher: CheckpointMatcher,
        flag: CancellationFlag,
        into acc: inout MappingAccumulator
    ) throws {
        let audioFile = try AVAudioFile(
            forReading: audioFileURL,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let format = audioFile.processingFormat
        let sampleRate = UInt32(format.sampleRate)
        let channels = UInt16(format.channelCount)

        let fileDurationSeconds = Double(audioFile.length) / format.sampleRate
        guard startSeconds < fileDurationSeconds else { throw StreamError.regionUnavailable }

        let startFrame = AVAudioFramePosition(startSeconds * format.sampleRate)
        if startFrame > 0 { audioFile.framePosition = startFrame }
        let endFrame = min(AVAudioFramePosition(endSeconds * format.sampleRate), audioFile.length)

        let streamer = StreamingWindowedFingerprinter(
            sampleRate: sampleRate,
            channels: channels,
            windowDurationMs: FingerprintConstants.windowDurationMs,
            windowIntervalMs: FingerprintConstants.windowIntervalMs
        )

        let chunkFrames = AVAudioFrameCount(format.sampleRate * FingerprintConstants.streamChunkSeconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrames) else {
            throw StreamError.bufferAllocationFailed
        }

        var interleaved: [Float] = []
        while audioFile.framePosition < endFrame {
            if flag.isCancelled { throw StreamError.cancelled }
            let framesRemaining = AVAudioFrameCount(endFrame - audioFile.framePosition)
            let framesToRead = min(framesRemaining, chunkFrames)
            try audioFile.read(into: buffer, frameCount: framesToRead)
            if buffer.frameLength == 0 { break }

            Self.interleave(buffer, into: &interleaved)
            let windows = streamer.pushSamplesF32(samples: interleaved, channels: channels)
            if !windows.isEmpty {
                Self.matchWindows(windows: windows, startOffset: startSeconds, matcher: matcher, into: &acc)
            }
        }

        if flag.isCancelled { throw StreamError.cancelled }
        let tail = streamer.flush()
        if !tail.isEmpty {
            Self.matchWindows(windows: tail, startOffset: startSeconds, matcher: matcher, into: &acc)
        }
    }

    /// Streaming-buffer variant of `streamFingerprint`. Same pipeline, but the
    /// file may not exist yet when we start, and grows while we read — so we
    /// reopen `AVAudioFile` each pass to refresh its length, seek to where we
    /// left off, and consume whatever new frames are available. Exits when the
    /// buffer has been stalled for `bufferGrowMaxStallSeconds` or the context
    /// is cancelled; a later `handlePlaybackProgress` restart will pick up
    /// again if the listener keeps playing.
    private func streamFingerprintGrowing(context ctx: GenerationContext, startingAt startSeconds: Double) throws {
        let pollCadence = FingerprintConstants.bufferGrowPollCadenceSeconds
        let maxStallSeconds = FingerprintConstants.bufferGrowMaxStallSeconds
        let trailingMarginSeconds = FingerprintConstants.bufferGrowTrailingMarginSeconds

        var streamer: StreamingWindowedFingerprinter?
        var format: AVAudioFormat?
        var buffer: AVAudioPCMBuffer?
        var chunkFrames: AVAudioFrameCount = 0
        var lastProcessedFrame: AVAudioFramePosition = 0
        var stallAccumSeconds: Double = 0
        var announcedFileAppeared = false
        var totalFramesRead: AVAudioFramePosition = 0
        var windowsEmitted = 0
        var interleaved: [Float] = []

        FileLog.shared.addMessage(
            "FingerprintTimingManager: streaming grow-loop starting at \(String(format: "%.1f", startSeconds))s "
                + "(buffer path: \(ctx.audioFileURL.lastPathComponent))"
        )

        while true {
            if ctx.isCancelled() { throw StreamError.cancelled }

            guard FileManager.default.fileExists(atPath: ctx.audioFileURL.path) else {
                // Streaming buffer not created yet — AVPlayer will write it
                // once it actually begins fetching bytes.
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try sleepWithCancellation(seconds: pollCadence, context: ctx)
                continue
            }

            let audioFile: AVAudioFile
            do {
                audioFile = try AVAudioFile(
                    forReading: ctx.audioFileURL,
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
            } catch {
                // Partial frame at the tail can make `AVAudioFile` refuse to
                // open momentarily — wait and retry.
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try sleepWithCancellation(seconds: pollCadence, context: ctx)
                continue
            }

            if !announcedFileAppeared {
                announcedFileAppeared = true
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming buffer opened "
                        + "(length \(audioFile.length) frames @ \(Int(audioFile.processingFormat.sampleRate))Hz, "
                        + "\(audioFile.processingFormat.channelCount)ch)"
                )
            }

            if streamer == nil {
                let fmt = audioFile.processingFormat
                let desiredStartFrame = max(0, AVAudioFramePosition(startSeconds * fmt.sampleRate))

                // The streaming buffer on disk is sequential from byte 0, so the
                // local file's frame `N` maps to audio timeline `N / sampleRate`.
                // If the buffer hasn't grown to `startSeconds` yet, reading from
                // the current tail and tagging those windows as `startSeconds +
                // windowTimestamp` would attribute them to the wrong reference
                // time — matches would fail. Wait until the file covers the
                // target position, then anchor `lastProcessedFrame` exactly there.
                guard audioFile.length >= desiredStartFrame else {
                    stallAccumSeconds += pollCadence
                    if stallAccumSeconds >= maxStallSeconds { break }
                    try sleepWithCancellation(seconds: pollCadence, context: ctx)
                    continue
                }

                format = fmt
                streamer = StreamingWindowedFingerprinter(
                    sampleRate: UInt32(fmt.sampleRate),
                    channels: UInt16(fmt.channelCount),
                    windowDurationMs: FingerprintConstants.windowDurationMs,
                    windowIntervalMs: FingerprintConstants.windowIntervalMs
                )
                chunkFrames = AVAudioFrameCount(fmt.sampleRate * FingerprintConstants.streamChunkSeconds)
                guard let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: chunkFrames) else {
                    throw StreamError.bufferAllocationFailed
                }
                buffer = b
                lastProcessedFrame = desiredStartFrame
            }

            guard let fmt = format, let str = streamer, let buf = buffer else { break }

            let trailingMarginFrames = AVAudioFramePosition(trailingMarginSeconds * fmt.sampleRate)
            let safeEnd = audioFile.length - trailingMarginFrames

            guard lastProcessedFrame < safeEnd else {
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try sleepWithCancellation(seconds: pollCadence, context: ctx)
                continue
            }

            audioFile.framePosition = lastProcessedFrame
            let framesAvailable = AVAudioFrameCount(safeEnd - lastProcessedFrame)
            let framesToRead = min(framesAvailable, chunkFrames)

            let nextChunkStartSeconds = Double(lastProcessedFrame) / fmt.sampleRate
            try throttleIfBeyondLookahead(nextChunkStartSeconds: nextChunkStartSeconds, context: ctx)

            do {
                try audioFile.read(into: buf, frameCount: framesToRead)
            } catch {
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try sleepWithCancellation(seconds: pollCadence, context: ctx)
                continue
            }

            if buf.frameLength == 0 {
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try sleepWithCancellation(seconds: pollCadence, context: ctx)
                continue
            }

            stallAccumSeconds = 0
            let framesJustRead = audioFile.framePosition - lastProcessedFrame
            lastProcessedFrame = audioFile.framePosition
            totalFramesRead += framesJustRead

            Self.interleave(buf, into: &interleaved)
            let windows = str.pushSamplesF32(samples: interleaved, channels: UInt16(fmt.channelCount))
            if !windows.isEmpty {
                windowsEmitted += windows.count
                dispatchProcessMatches(windows: windows, startOffset: startSeconds, context: ctx)
            }
        }

        if ctx.isCancelled() { throw StreamError.cancelled }
        if let str = streamer {
            let tail = str.flush()
            if !tail.isEmpty {
                windowsEmitted += tail.count
                dispatchProcessMatches(windows: tail, startOffset: startSeconds, context: ctx)
            }
        }

        let readSeconds = (format.map { Double(totalFramesRead) / $0.sampleRate }) ?? 0
        FileLog.shared.addMessage(
            "FingerprintTimingManager: streaming grow-loop ending — "
                + "read \(String(format: "%.1f", readSeconds))s of audio, "
                + "emitted \(windowsEmitted) windows, "
                + "stall accum \(String(format: "%.1f", stallAccumSeconds))s"
        )
    }

    /// Once the streaming loop reaches EOF, persist the committed mapping to
    /// disk if (and only if) it covers the whole reference timeline for this
    /// audio file. The cache is then a complete replacement on next open —
    /// `FingerprintMappingCache.save` enforces the same coverage threshold the
    /// load path requires, keeping the round-trip safe.
    ///
    /// Only the snapshot read runs on `queue`; JSON encoding + disk I/O happen
    /// on `generationQueue` so they don't stall `queue.sync` callers (the
    /// `referenceTime(forPlaybackTime:)` / `playbackTime(forReferenceTime:)`
    /// queries that drive transcript highlighting and tap-to-seek).
    ///
    /// Guarded on `episodeUuid` rather than `generation`: the question here is
    /// whether `main` still holds this episode's mapping, and a restart keeps
    /// that mapping intact for the same audio file and reference.
    private func persistMappingCacheIfFull(context ctx: GenerationContext) {
        guard !ctx.isStreaming else { return }
        queue.async { [weak self] in
            guard let self, self.context?.episodeUuid == ctx.episodeUuid else { return }
            let snapshot = self.main.playbackToReference
            self.generationQueue.async {
                FingerprintMappingCache.save(
                    snapshot,
                    audioFilePath: ctx.audioFileURL.path,
                    referenceFilePath: ctx.referenceFilePath,
                    referenceData: ctx.referenceData,
                    referenceDuration: ctx.referenceDuration
                )
            }
        }
    }

    /// Yield CPU briefly when the next chunk to fingerprint sits more than
    /// `lookaheadSeconds` ahead of the listener's current playback time. This
    /// keeps coverage growing to EOF — the chunk is **never** skipped — while
    /// bounding peak CPU on long episodes the listener hasn't reached yet.
    /// Capping the loop instead of throttling it (the prior POC-546 attempt)
    /// dropped tail regions from the mapping and broke tap-to-seek for any cue
    /// further than `lookaheadSeconds` ahead.
    private func throttleIfBeyondLookahead(
        nextChunkStartSeconds: Double,
        context ctx: GenerationContext
    ) throws {
        let currentPlayback = PlaybackManager.shared.currentTime()
        let lead = nextChunkStartSeconds - currentPlayback
        guard lead > FingerprintConstants.lookaheadSeconds else { return }
        try sleepWithCancellation(
            seconds: FingerprintConstants.outsideLookaheadSleepSeconds,
            context: ctx
        )
    }

    /// Sleep on the generation queue in small slices so cancellation is
    /// observed within at most one slice. Tracks remaining time rather than
    /// ceiling-rounding the slice count so we don't oversleep the requested
    /// duration by up to one slice (e.g. 0.21s → 0.4s).
    private func sleepWithCancellation(seconds: TimeInterval, context ctx: GenerationContext) throws {
        let sliceSeconds: TimeInterval = 0.2
        var remaining = max(0, seconds)
        while remaining > 0 {
            if ctx.isCancelled() { throw StreamError.cancelled }
            let sleepDuration = min(sliceSeconds, remaining)
            Thread.sleep(forTimeInterval: sleepDuration)
            remaining -= sleepDuration
        }
    }

    private func dispatchProcessMatches(
        windows: [WindowedFingerprint],
        startOffset: Double,
        context ctx: GenerationContext
    ) {
        queue.async { [weak self] in
            guard let self, self.context?.generation == ctx.generation else { return }
            self.processMatches(windows: windows, startOffset: startOffset, context: ctx)
        }
    }

    /// Interleaves the buffer's planar Float32 channels into `scratch`, reusing
    /// its storage across chunks. `scratch` is resized only when the sample
    /// count changes (in practice once, plus once more for a short final
    /// chunk), so a decode loop allocates O(1) arrays instead of one per chunk.
    private static func interleave(_ buffer: AVAudioPCMBuffer, into scratch: inout [Float]) {
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameCount > 0, channelCount > 0,
              let channelData = buffer.floatChannelData else {
            scratch.removeAll(keepingCapacity: true)
            return
        }

        let sampleCount = frameCount * channelCount
        if scratch.count != sampleCount {
            scratch = [Float](repeating: 0, count: sampleCount)
        }
        scratch.withUnsafeMutableBufferPointer { dst in
            guard let base = dst.baseAddress else { return }
            if channelCount == 1 {
                base.update(from: channelData[0], count: frameCount)
                return
            }
            // Strided vector copy (add-zero) — one vDSP pass per channel
            // instead of a scalar store per sample.
            var zero: Float = 0
            for ch in 0..<channelCount {
                vDSP_vsadd(channelData[ch], 1, &zero, base + ch, vDSP_Stride(channelCount), vDSP_Length(frameCount))
            }
        }
    }

    private enum StreamError: Error {
        case cancelled
        case bufferAllocationFailed
        /// The requested audio region isn't present in the local file yet (a
        /// streaming episode whose buffer hasn't reached the target chapter).
        case regionUnavailable
    }

    private func processMatches(
        windows: [WindowedFingerprint],
        startOffset: Double,
        context ctx: GenerationContext
    ) {
        Self.matchWindows(windows: windows, startOffset: startOffset, matcher: ctx.matcher, into: &main)

        let coverage = main.playbackToReference.count
        if coverage >= FingerprintConstants.minimumCoverageForActive {
            updateState(.active(coverage: coverage))
            if !hasReachedActive {
                hasReachedActive = true
                track(.syncedTranscriptsPreparationCompleted, properties: [
                    "duration_ms": preparationDurationMs,
                    "is_streaming": context?.isStreaming ?? false
                ])
            }
        }
    }

    /// The core match loop shared by the continuous transcript path and the
    /// one-shot resolves: run each window through `matcher`, apply the
    /// score/dominance gates, and route survivors through the drift filter into
    /// `acc`. Returns the number of mappings committed this call.
    ///
    /// Pure in `acc`: it reads and writes nothing else, so each caller only needs
    /// exclusive access to the accumulator it passes in. The continuous path's
    /// `main` is serialized on `queue`; the one-shot resolves own a local
    /// accumulator outright and need no synchronization at all.
    @discardableResult
    private static func matchWindows(
        windows: [WindowedFingerprint],
        startOffset: Double,
        matcher: CheckpointMatcher,
        into acc: inout MappingAccumulator
    ) -> Int {
        var inserted = 0
        #if DEBUG
        var bestScoreOverall: Float = 0
        var nonZeroScoreCount = 0
        var scoreSum: Float = 0
        #endif

        for window in windows {
            // Pull top-2 so we can check how dominant the winner is — ambiguous
            // wins (top-1 barely beats top-2) are the hallmark of correlated
            // false positives from non-matching audio.
            let matches = matcher.findTopMatches(
                queryHashes: window.hashes,
                maxResults: 2
            )
            guard let best = matches.first else { continue }

            #if DEBUG
            if best.score > 0 {
                nonZeroScoreCount += 1
                scoreSum += best.score
            }
            if best.score > bestScoreOverall { bestScoreOverall = best.score }
            #endif
            guard best.score >= FingerprintConstants.matchScoreThreshold else { continue }

            let absolutePlaybackTime = startOffset + Double(window.timestampMs) / 1000.0
            let candidate = TimeMappingEntry(
                playbackTime: absolutePlaybackTime,
                referenceTime: Double(best.timestamp),
                score: best.score
            )

            // Pre-filter gates. Low-score and ambiguous matches are recorded as
            // rejections so the debug overlay can visualize "matcher fired but
            // we didn't trust it" distinctly from "matcher never fired here".
            if best.score < FingerprintConstants.driftAnchorScoreThreshold {
                recordRejection(
                    candidate,
                    reason: "low score \(String(format: "%.2f", best.score))",
                    into: &acc
                )
                continue
            }
            let runnerUpScore = matches.dropFirst().first?.score ?? 0
            let dominance = best.score - runnerUpScore
            if dominance < FingerprintConstants.driftScoreDominanceGap {
                recordRejection(
                    candidate,
                    reason: "ambiguous top-1 vs top-2 "
                        + "(\(String(format: "%.2f", best.score)) vs \(String(format: "%.2f", runnerUpScore)))",
                    into: &acc
                )
                continue
            }

            inserted += consider(candidate: candidate, into: &acc)
        }

        #if DEBUG
        // `inserted` is the mapping count committed during this call, not a
        // ratio to windows processed — the drift filter holds candidates in a
        // pool across batches and can flush several at once on confirmation, so
        // `inserted` may exceed `windows.count` (or be zero while the pool is
        // still accumulating). Report them as independent quantities.
        let avgNonZero = nonZeroScoreCount > 0 ? scoreSum / Float(nonZeroScoreCount) : 0
        FileLog.shared.addMessage(
            "FingerprintTimingManager: processed \(windows.count) windows, "
                + "committed \(inserted) mappings "
                + "(coverage: \(acc.playbackToReference.count), bestScore: \(String(format: "%.3f", bestScoreOverall)), "
                + "nonZero: \(nonZeroScoreCount), avgNonZero: \(String(format: "%.3f", avgNonZero)))"
        )
        #endif
        return inserted
    }

    // MARK: - Drift Filter

    /// Routes a score-passing candidate through the drift filter. Returns the
    /// number of entries actually inserted into the mapping arrays this call.
    ///
    /// Invariant the filter enforces:
    /// **no anchor — bootstrap or post-jump — is admitted until we've seen
    /// `driftBootstrapCount` consecutive rate-≈1 candidates in a row.**
    ///
    /// - Fast path: candidate is in-trend with `filterLastTrusted` → commit
    ///   immediately, flush any pooled candidates as rejections (a prior jump
    ///   attempt that didn't pan out turned out to be noise).
    /// - Slow path: candidate goes into `filterCandidatePool`. Once the pool's
    ///   tail is `driftBootstrapCount` consecutive consistent entries, commit
    ///   them all and drop anything before as rejections. Otherwise evict the
    ///   oldest and keep rolling.
    ///
    /// This is the same rule for the initial bootstrap (no `lastTrusted` yet)
    /// and for post-trusted jumps, so a single lucky pair can never admit an
    /// anchor — what the user was seeing as "jump-arounds" in the debug UI.
    @discardableResult
    private static func consider(candidate: TimeMappingEntry, into acc: inout MappingAccumulator) -> Int {
        if let trusted = acc.filterLastTrusted, isInTrend(candidate, relativeTo: trusted) {
            // Sequential continuation. Anything that had collected in the pool
            // was a jump attempt that never stabilized — reject it.
            flushPoolAsRejected(reason: "returned to trend", into: &acc)
            insertMapping(candidate, into: &acc)
            acc.filterLastTrusted = candidate
            return 1
        }

        acc.filterCandidatePool.append(candidate)
        let n = FingerprintConstants.driftBootstrapCount

        guard acc.filterCandidatePool.count >= n else { return 0 }

        let recent = Array(acc.filterCandidatePool.suffix(n))
        if formsConsistentSequence(recent) {
            // Confirmed new anchor. Anything older in the pool is noise.
            let keepStart = acc.filterCandidatePool.count - n
            if keepStart > 0 {
                let evicted = Array(acc.filterCandidatePool.prefix(keepStart))
                for entry in evicted {
                    recordRejection(entry, reason: "pool evicted by confirmed anchor", into: &acc)
                }
            }
            #if DEBUG
            FileLog.shared.addMessage(
                "FingerprintTimingManager: drift filter confirmed anchor "
                    + "at playback \(String(format: "%.1f", recent.first!.playbackTime))s → "
                    + "\(String(format: "%.1f", recent.last!.playbackTime))s "
                    + "(\(n) consistent)"
            )
            #endif
            for entry in recent {
                insertMapping(entry, into: &acc)
            }
            acc.filterLastTrusted = recent.last
            acc.filterCandidatePool.removeAll()
            return n
        }

        // Not consistent yet — evict oldest and keep waiting for the window to
        // roll onto a consistent stretch.
        let evicted = acc.filterCandidatePool.removeFirst()
        recordRejection(evicted, reason: "pool evicted, no consistent run", into: &acc)
        return 0
    }

    private static func flushPoolAsRejected(reason: String, into acc: inout MappingAccumulator) {
        let pooled = acc.filterCandidatePool
        acc.filterCandidatePool.removeAll()
        for entry in pooled {
            recordRejection(entry, reason: reason, into: &acc)
        }
    }

    /// Two entries are in-trend when `Δreference ≈ Δplayback` (rate ≈ 1),
    /// within `driftToleranceSeconds` of residual slack.
    private static func isInTrend(_ candidate: TimeMappingEntry, relativeTo anchor: TimeMappingEntry) -> Bool {
        let deltaPlayback = candidate.playbackTime - anchor.playbackTime
        let deltaReference = candidate.referenceTime - anchor.referenceTime
        return abs(deltaReference - deltaPlayback) <= FingerprintConstants.driftToleranceSeconds
    }

    private static func formsConsistentSequence(_ entries: [TimeMappingEntry]) -> Bool {
        guard entries.count >= 2 else { return true }
        for i in 1..<entries.count where !isInTrend(entries[i], relativeTo: entries[i - 1]) {
            return false
        }
        return true
    }

    private static func recordRejection(
        _ entry: TimeMappingEntry,
        reason: String,
        into acc: inout MappingAccumulator
    ) {
        #if DEBUG
        FileLog.shared.addMessage(
            "FingerprintTimingManager: drift filter dropped \(reason) "
                + "at playback \(String(format: "%.1f", entry.playbackTime))s "
                + "(matched reference \(String(format: "%.1f", entry.referenceTime))s)"
        )
        acc.rejections.append(entry)
        if acc.rejections.count > debugRejectionCap {
            acc.rejections.removeFirst(acc.rejections.count - debugRejectionCap)
        }
        #endif
    }

    // MARK: - Time Mapping

    /// Test seam: inserts a mapping on the manager's serial queue so queries are
    /// consistent with production insertions that happen from within `processMatches`.
    func insert(mapping: TimeMappingEntry) {
        queue.sync {
            Self.insertMapping(mapping, into: &main)
        }
    }

    /// Test seam: routes a sequence of candidates through the drift filter
    /// synchronously on the manager's serial queue, the way `processMatches`
    /// does in production.
    func stubMatches(_ entries: [TimeMappingEntry]) {
        queue.sync {
            for entry in entries {
                Self.consider(candidate: entry, into: &main)
            }
        }
    }

    private static func insertMapping(_ entry: TimeMappingEntry, into acc: inout MappingAccumulator) {
        let pbIdx = acc.playbackToReference.sortedInsertionIndex { $0.playbackTime < entry.playbackTime }
        acc.playbackToReference.insert(entry, at: pbIdx)

        let refIdx = acc.referenceToPlayback.sortedInsertionIndex { $0.referenceTime < entry.referenceTime }
        acc.referenceToPlayback.insert(entry, at: refIdx)
    }

    static func interpolate(
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
    static func isWithinMatchedContent(
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

    // MARK: - Helpers

    private func loadReference(for episode: BaseEpisode) -> (data: Data, reference: ReferenceFingerprint)? {
        let path = referencePath(for: episode)
        guard let data = FileManager.default.contents(atPath: path),
              let reference = ReferenceFingerprint.decode(from: data) else { return nil }
        return (data, reference)
    }

    private func referencePath(for episode: BaseEpisode) -> String {
        let audioPath = DownloadManager.shared.pathForEpisode(episode)
        return (audioPath as NSString).deletingPathExtension + ".ref.fp.json"
    }

    private func saveReferenceData(_ data: Data, for episode: BaseEpisode) {
        let path = referencePath(for: episode)
        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            FileLog.shared.addMessage("FingerprintTimingManager: saved reference to disk for \(episode.uuid)")
        } catch {
            FileLog.shared.addMessage("FingerprintTimingManager: failed to save reference — \(error.localizedDescription)")
        }
    }

    /// Which local file backs the fingerprint loop for this episode.
    ///
    /// - `.downloaded` is a complete file — the existing read-to-EOF loop handles it.
    /// - `.streaming` points at the AVPlayer-written buffer, which may be absent at
    ///   call time or still growing. The grow-loop waits for it to appear and
    ///   polls for new bytes.
    private enum AudioSource {
        case downloaded(URL)
        case streaming(URL)
    }

    private func resolveAudioSource(for episode: BaseEpisode) -> AudioSource {
        let downloadPath = DownloadManager.shared.pathForEpisode(episode)
        if FileManager.default.fileExists(atPath: downloadPath) {
            return .downloaded(URL(fileURLWithPath: downloadPath))
        }
        // A stream-downloaded episode keeps a complete file at the streaming
        // buffer path. It isn't growing, so route it through the one-shot
        // fingerprint path instead of the grow-loop — same path trunk took.
        if let episode = episode as? Episode,
           episode.streamDownloaded(pathFinder: DownloadManager.shared) {
            let streamingPath = DownloadManager.shared.streamingBufferPathForEpisode(episode)
            if FileManager.default.fileExists(atPath: streamingPath) {
                return .downloaded(URL(fileURLWithPath: streamingPath))
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
            return .streaming(URL(fileURLWithPath: tempPath))
        }
        if FileManager.default.fileExists(atPath: streamingPath) {
            return .streaming(URL(fileURLWithPath: streamingPath))
        }
        let preferred = FeatureFlag.streamAndCachePlayingEpisode.enabled ? tempPath : streamingPath
        return .streaming(URL(fileURLWithPath: preferred))
    }
}

// MARK: - Cancellation

private final class CancellationFlag: Sendable {
    private let cancelled = OSAllocatedUnfairLock(initialState: false)

    var isCancelled: Bool {
        cancelled.withLock { $0 }
    }

    func cancel() {
        cancelled.withLock { $0 = true }
    }
}

// MARK: - Array Sorted Insertion

private extension Array {
    func sortedInsertionIndex(isOrderedBefore: (Element) -> Bool) -> Int {
        var lo = 0
        var hi = count
        while lo < hi {
            let mid = (lo + hi) / 2
            if isOrderedBefore(self[mid]) {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }
}
