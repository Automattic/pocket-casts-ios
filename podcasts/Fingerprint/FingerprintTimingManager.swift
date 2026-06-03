import AVFoundation
import Foundation
import Fingerprint
import PocketCastsDataModel
import PocketCastsUtils

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

    /// True while the listener is inside a stretch of audio the matcher no longer
    /// recognises — typically a dynamically inserted mid-roll ad. Updated on the
    /// main thread; read it from the transcript UI to stop highlighting during
    /// ads. Transitions also post `Constants.Notifications.fingerprintAdStateChanged`.
    private(set) var isAdInProgress = false

    // MARK: - Internal Types

    private struct GenerationContext {
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

    // MARK: - Private State

    private let queue = DispatchQueue(label: "au.com.pocketcasts.FingerprintTimingManager")
    private let generationQueue = DispatchQueue(
        label: "au.com.pocketcasts.FingerprintTimingManager.generation",
        qos: .utility
    )
    private var context: GenerationContext?
    private var cancellationFlag = CancellationFlag()
    private var fetchTask: Task<Void, Never>?
    private var playbackToReference: [TimeMappingEntry] = []
    private var referenceToPlayback: [TimeMappingEntry] = []
    private var lastProgressPosition: Double = -1

    private var preparationStartDate: Date?
    private var hasReachedActive = false
    private var hasEmittedPreparationStarted = false

    /// Queue-confined mirror of `isAdInProgress` used to detect transitions
    /// without hopping to the main thread on every progress tick.
    private var adInProgress = false

    /// Playback-axis range, in seconds, the fingerprint loop has actually
    /// examined for the current stream. Anything inside this range that produced
    /// no matched anchor is genuinely unmatched audio (an ad); anything outside
    /// it simply hasn't been generated yet, so we can't call it. `start` is where
    /// the current stream was anchored, `frontier` is the furthest window matched
    /// so far. Default ordering (start > frontier) means "nothing processed yet".
    private var processedStart: Double = .greatestFiniteMagnitude
    private var processedFrontier: Double = -1

    // Drift-filter state — see `consider(candidate:)`.
    private var filterLastTrusted: TimeMappingEntry?
    private var filterCandidatePool: [TimeMappingEntry] = []

    #if DEBUG
    private static let debugRejectionCap = 500
    private var debugRejections: [TimeMappingEntry] = []
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
        let episode = PlaybackManager.shared.currentEpisode()

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
              let currentUuid = PlaybackManager.shared.currentEpisode()?.uuid,
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

        let episodeUuid = PlaybackManager.shared.currentEpisode()?.uuid
        queue.async { [weak self] in
            self?.processProgress(playbackTime: playbackTime, episodeUuid: episodeUuid)
        }
    }

    private func processProgress(playbackTime: Double, episodeUuid: String?) {
        guard let ctx = context, ctx.episodeUuid == episodeUuid else { return }

        evaluateAdState(playbackTime: playbackTime)

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
        if playbackToReference.isEmpty { return }

        #if DEBUG
        FileLog.shared.addMessage(
            "FingerprintTimingManager: playback at \(String(format: "%.1f", playbackTime))s outside mapped range — restarting"
        )
        #endif
        restart(from: playbackTime, context: ctx)
    }

    // MARK: - Ad Detection

    /// Decide whether the current playback position sits in an ad and flip
    /// `isAdInProgress` accordingly.
    ///
    /// The position is an ad when it falls inside an unmatched stretch wider than
    /// `adCoverageGapSeconds`. During matched playback anchors land roughly every
    /// window interval, so a stretch this wide is content the matcher refused.
    /// The stretch is bounded by:
    /// - below: the nearest anchor at or before the position, or — when there's
    ///   none (the position is before the first anchor, i.e. a pre-roll) — the
    ///   point where the loop began examining audio (`processedStart`);
    /// - above: the nearest anchor at or after the position, or — when there's
    ///   none (the position is beyond the last anchor, i.e. a post-roll or
    ///   mid-roll not yet exited) — how far the loop has confirmed unmatched
    ///   (`processedFrontier`).
    ///
    /// Measuring the full bounded width, rather than the distance to the nearest
    /// anchor, matters because the first anchor after an ad sits exactly where
    /// real content resumes and is usually committed (the loop runs ahead) while
    /// the listener is still in the ad; distance-to-nearest would clear the ad up
    /// to `adCoverageGapSeconds` early as playback merely approached it.
    ///
    /// Only positions the loop has actually examined are judged. Outside
    /// `[processedStart, processedFrontier]` coverage simply hasn't been generated
    /// yet (notably the live-streaming edge), and flagging an ad there would
    /// suppress legitimate highlighting.
    private func evaluateAdState(playbackTime: Double) {
        guard hasReachedActive,
              playbackTime >= processedStart,
              playbackTime <= processedFrontier else {
            setAdInProgress(false)
            return
        }

        let below = lastAnchorIndex(atOrBefore: playbackTime)
        // The anchor bounding the position from above: the one after `below`, or
        // the very first anchor when the position precedes them all (pre-roll).
        let above: Int?
        if let below {
            let next = below + 1
            above = playbackToReference.indices.contains(next) ? next : nil
        } else {
            above = playbackToReference.isEmpty ? nil : 0
        }

        let lowerBound = below.map { playbackToReference[$0].playbackTime } ?? processedStart
        let upperBound = above.map { playbackToReference[$0].playbackTime } ?? processedFrontier

        setAdInProgress(upperBound - lowerBound > FingerprintConstants.adCoverageGapSeconds)
    }

    /// Index of the last anchor whose `playbackTime` is `<= playbackTime`, or nil
    /// if the position is before every anchor.
    private func lastAnchorIndex(atOrBefore playbackTime: Double) -> Int? {
        guard let first = playbackToReference.first, playbackTime >= first.playbackTime else { return nil }
        var lo = 0
        var hi = playbackToReference.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if playbackToReference[mid].playbackTime <= playbackTime {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
    }

    private func setAdInProgress(_ inAd: Bool) {
        guard inAd != adInProgress else { return }
        adInProgress = inAd
        #if DEBUG
        FileLog.shared.addMessage("FingerprintTimingManager: ad \(inAd ? "started" : "ended")")
        #endif
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isAdInProgress = inAd
            NotificationCenter.default.post(name: Constants.Notifications.fingerprintAdStateChanged, object: nil)
        }
    }

    private func isWithinMappedRange(_ playbackTime: Double) -> Bool {
        guard let first = playbackToReference.first,
              let last = playbackToReference.last else { return false }
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
                in: playbackToReference,
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
                in: referenceToPlayback,
                keyPath: \.referenceTime,
                valuePath: \.playbackTime
            )
        }
    }

    #if DEBUG
    var totalDuration: Double? {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync { context?.duration }
    }

    func debugMappingSnapshot() -> [TimeMappingEntry] {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync { playbackToReference }
    }

    /// Candidates that reached the drift filter but were rejected. The debug
    /// overlay uses this to distinguish "matcher never fired here" from
    /// "matcher fired but everything was filtered out as noise".
    func debugRejectionsSnapshot() -> [TimeMappingEntry] {
        dispatchPrecondition(condition: .notOnQueue(queue))
        return queue.sync { debugRejections }
    }
    #endif

    // MARK: - State Management

    private func resetState() {
        fetchTask?.cancel()
        fetchTask = nil
        cancellationFlag.cancel()
        cancellationFlag = CancellationFlag()
        context = nil
        playbackToReference.removeAll()
        referenceToPlayback.removeAll()
        lastProgressPosition = -1
        preparationStartDate = nil
        hasReachedActive = false
        hasEmittedPreparationStarted = false
        processedStart = .greatestFiniteMagnitude
        processedFrontier = -1
        setAdInProgress(false)
        resetFilterState()
        #if DEBUG
        debugRejections.removeAll()
        #endif
    }

    private func resetFilterState() {
        filterLastTrusted = nil
        filterCandidatePool.removeAll()
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
            track(.syncedTranscriptUnavailable, properties: ["reason": "feature_disabled"])
            return
        }

        guard let episode else {
            updateState(.unavailable)
            track(.syncedTranscriptUnavailable, properties: ["reason": "no_episode"])
            return
        }

        let uuid = episode.uuid

        if let loaded = loadReference(for: episode) {
            configureForReference(loaded.reference, referenceData: loaded.data, episode: episode)
            return
        }

        preparationStartDate = Date()
        updateState(.preparing)
        track(.syncedTranscriptPreparationStarted, properties: [
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
                    self.track(.syncedTranscriptUnavailable, properties: ["reason": "no_reference"])
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
            track(.syncedTranscriptUnavailable, properties: ["reason": "invalid_duration"])
            return
        }

        let matcher = CheckpointMatcher()
        let duration_s = reference.checkpointDurationSeconds
        let rawCheckpointCount = reference.checkpoints.count
        let libraryCheckpoints = reference.libraryCheckpoints()

        FileLog.shared.addMessage(
            "FingerprintTimingManager: reference for \(uuid) — "
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
                    + "(audio duration \(String(format: "%.1f", duration))s)"
            )
        }

        guard !libraryCheckpoints.isEmpty else {
            updateState(.unavailable)
            track(.syncedTranscriptUnavailable, properties: ["reason": "no_reference"])
            FileLog.shared.addMessage("FingerprintTimingManager: reference for \(uuid) has no usable checkpoints")
            return
        }

        for checkpoint in libraryCheckpoints {
            matcher.add(
                timestamp: checkpoint.timestampSeconds,
                hashes: checkpoint.hashes,
                duration: duration_s
            )
        }

        let flag = cancellationFlag
        let refPath = referencePath(for: episode)
        let newContext = GenerationContext(
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
            track(.syncedTranscriptPreparationStarted, properties: [
                "is_streaming": isStreaming,
                "episode_duration_seconds": duration
            ])
            hasEmittedPreparationStarted = true
        }
        FileLog.shared.addMessage(
            "FingerprintTimingManager: preparing for \(uuid) (\(libraryCheckpoints.count) checkpoints)"
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
            playbackToReference = cached.entries
            referenceToPlayback = cached.entries.sorted { $0.referenceTime < $1.referenceTime }
            // A full-coverage cache is only written after a prior session
            // fingerprinted the entire file, so the whole timeline counts as
            // processed — gaps in it are real ads, including pre/post-roll.
            processedStart = 0
            processedFrontier = duration

            if isWithinMappedRange(currentTime) {
                filterLastTrusted = cached.entries.last
                let coverage = cached.entries.count
                updateState(.active(coverage: coverage))
                if !hasReachedActive {
                    hasReachedActive = true
                    track(.syncedTranscriptPreparationCompleted, properties: [
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

    // MARK: - Streaming Fingerprint Processing

    /// Stream-decode the downloaded file with `AVAudioFile`, push PCM into the
    /// streaming fingerprinter chunk-by-chunk, and match each batch of windows
    /// as soon as it's emitted. We start near the current playback position
    /// (snapped to a 2s grid so window timestamps line up with the reference
    /// checkpoints), so highlighting becomes usable for what the listener is
    /// actually hearing — without waiting for the entire file to be processed.
    private func startStream(context ctx: GenerationContext, fromPosition position: Double) {
        let aligned = Self.alignToWindowGrid(position)
        // A (re)started stream re-examines the audio from `aligned` forward, so
        // the confirmed-processed range collapses to that point and grows again
        // as windows are matched. Ad detection only trusts this range.
        processedStart = aligned
        processedFrontier = aligned
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
            guard let self, self.context?.episodeUuid == ctx.episodeUuid else { return }
            let durationMs = self.preparationDurationMs
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if case .active = self.state { return }
                self.state = terminalState
                switch terminalState {
                case .failed(let error):
                    let nsError = error as NSError
                    self.track(.syncedTranscriptPreparationFailed, properties: [
                        "error_code": nsError.code,
                        "error_domain": nsError.domain,
                        "stage": "fingerprint_generation",
                        "duration_ms": durationMs
                    ])
                case .unavailable:
                    let reason = ctx.isStreaming ? "streaming_unsupported" : "no_matches"
                    self.track(.syncedTranscriptUnavailable, properties: [
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

        while true {
            if ctx.isCancelled() { throw StreamError.cancelled }
            let nextChunkStartSeconds = Double(audioFile.framePosition) / format.sampleRate
            try throttleIfBeyondLookahead(nextChunkStartSeconds: nextChunkStartSeconds, context: ctx)
            try audioFile.read(into: buffer, frameCount: chunkFrames)
            if buffer.frameLength == 0 { break }

            let interleaved = Self.interleavedSamples(from: buffer)
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

            let interleaved = Self.interleavedSamples(from: buf)
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
    private func persistMappingCacheIfFull(context ctx: GenerationContext) {
        guard !ctx.isStreaming else { return }
        queue.async { [weak self] in
            guard let self, self.context?.episodeUuid == ctx.episodeUuid else { return }
            let snapshot = self.playbackToReference
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
            guard let self, self.context?.episodeUuid == ctx.episodeUuid else { return }
            self.processMatches(windows: windows, startOffset: startOffset, context: ctx)
        }
    }

    private static func interleavedSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameCount > 0, channelCount > 0,
              let channelData = buffer.floatChannelData else { return [] }

        var result = [Float](repeating: 0, count: frameCount * channelCount)
        for ch in 0..<channelCount {
            let src = channelData[ch]
            for frame in 0..<frameCount {
                result[frame * channelCount + ch] = src[frame]
            }
        }
        return result
    }

    private enum StreamError: Error {
        case cancelled
        case bufferAllocationFailed
    }

    private func processMatches(
        windows: [WindowedFingerprint],
        startOffset: Double,
        context ctx: GenerationContext
    ) {
        // Advance the processed frontier to the end of this batch regardless of
        // whether anything matched — windows are emitted continuously, so a
        // stretch examined here that commits no anchor is confirmed unmatched
        // audio (an ad), which is exactly what ad detection needs to know.
        // `timestampMs` is the window's start, so add its duration to reach the
        // audio actually examined; otherwise the frontier trails by up to one
        // window and ad detection would briefly treat positions near it as
        // unprocessed, flickering highlighting back on right behind the edge.
        if let lastWindow = windows.last {
            let batchEnd = startOffset + Double(lastWindow.timestampMs + lastWindow.durationMs) / 1000.0
            processedFrontier = max(processedFrontier, batchEnd)
        }

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
            let matches = ctx.matcher.findTopMatches(
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
                recordRejection(candidate, reason: "low score \(String(format: "%.2f", best.score))")
                continue
            }
            let runnerUpScore = matches.dropFirst().first?.score ?? 0
            let dominance = best.score - runnerUpScore
            if dominance < FingerprintConstants.driftScoreDominanceGap {
                recordRejection(
                    candidate,
                    reason: "ambiguous top-1 vs top-2 "
                        + "(\(String(format: "%.2f", best.score)) vs \(String(format: "%.2f", runnerUpScore)))"
                )
                continue
            }

            inserted += consider(candidate: candidate)
        }

        let coverage = playbackToReference.count
        if coverage >= FingerprintConstants.minimumCoverageForActive {
            updateState(.active(coverage: coverage))
            if !hasReachedActive {
                hasReachedActive = true
                track(.syncedTranscriptPreparationCompleted, properties: [
                    "duration_ms": preparationDurationMs,
                    "is_streaming": context?.isStreaming ?? false
                ])
            }
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
                + "(coverage: \(coverage), bestScore: \(String(format: "%.3f", bestScoreOverall)), "
                + "nonZero: \(nonZeroScoreCount), avgNonZero: \(String(format: "%.3f", avgNonZero)))"
        )
        #endif
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
    private func consider(candidate: TimeMappingEntry) -> Int {
        if let trusted = filterLastTrusted, Self.isInTrend(candidate, relativeTo: trusted) {
            // Sequential continuation. Anything that had collected in the pool
            // was a jump attempt that never stabilized — reject it.
            flushPoolAsRejected(reason: "returned to trend")
            insertMapping(candidate)
            filterLastTrusted = candidate
            return 1
        }

        filterCandidatePool.append(candidate)
        let n = FingerprintConstants.driftBootstrapCount

        guard filterCandidatePool.count >= n else { return 0 }

        let recent = Array(filterCandidatePool.suffix(n))
        if Self.formsConsistentSequence(recent) {
            // Confirmed new anchor. Anything older in the pool is noise.
            let keepStart = filterCandidatePool.count - n
            if keepStart > 0 {
                for entry in filterCandidatePool.prefix(keepStart) {
                    recordRejection(entry, reason: "pool evicted by confirmed anchor")
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
                insertMapping(entry)
            }
            filterLastTrusted = recent.last
            filterCandidatePool.removeAll()
            return n
        }

        // Not consistent yet — evict oldest and keep waiting for the window to
        // roll onto a consistent stretch.
        let evicted = filterCandidatePool.removeFirst()
        recordRejection(evicted, reason: "pool evicted, no consistent run")
        return 0
    }

    private func flushPoolAsRejected(reason: String) {
        for entry in filterCandidatePool {
            recordRejection(entry, reason: reason)
        }
        filterCandidatePool.removeAll()
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

    private func recordRejection(_ entry: TimeMappingEntry, reason: String) {
        #if DEBUG
        FileLog.shared.addMessage(
            "FingerprintTimingManager: drift filter dropped \(reason) "
                + "at playback \(String(format: "%.1f", entry.playbackTime))s "
                + "(matched reference \(String(format: "%.1f", entry.referenceTime))s)"
        )
        debugRejections.append(entry)
        if debugRejections.count > Self.debugRejectionCap {
            debugRejections.removeFirst(debugRejections.count - Self.debugRejectionCap)
        }
        #endif
    }

    // MARK: - Time Mapping

    /// Test seam: inserts a mapping on the manager's serial queue so queries are
    /// consistent with production insertions that happen from within `processMatches`.
    func insert(mapping: TimeMappingEntry) {
        queue.sync { insertMapping(mapping) }
    }

    /// Test seam: routes a sequence of candidates through the drift filter
    /// synchronously on the manager's serial queue, the way `processMatches`
    /// does in production.
    func stubMatches(_ entries: [TimeMappingEntry]) {
        queue.sync {
            for entry in entries {
                _ = consider(candidate: entry)
            }
        }
    }

    /// Test seam: configures the processed range plus the active flag and runs
    /// the ad-detection evaluation synchronously on the manager's serial queue —
    /// the way `processProgress` does each tick — returning the resulting
    /// queue-confined ad state. The public `isAdInProgress` mirror is updated
    /// asynchronously on the main thread, so tests read this return value to stay
    /// deterministic. Set up the anchor mapping first via `insert(mapping:)`.
    func evaluateAdStateForTesting(
        playbackTime: Double,
        processedStart: Double,
        processedFrontier: Double,
        hasReachedActive: Bool = true
    ) -> Bool {
        queue.sync {
            self.hasReachedActive = hasReachedActive
            self.processedStart = processedStart
            self.processedFrontier = processedFrontier
            evaluateAdState(playbackTime: playbackTime)
            return adInProgress
        }
    }

    private func insertMapping(_ entry: TimeMappingEntry) {
        let pbIdx = playbackToReference.sortedInsertionIndex { $0.playbackTime < entry.playbackTime }
        playbackToReference.insert(entry, at: pbIdx)

        let refIdx = referenceToPlayback.sortedInsertionIndex { $0.referenceTime < entry.referenceTime }
        referenceToPlayback.insert(entry, at: refIdx)
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

private final class CancellationFlag {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.withLock { cancelled }
    }

    func cancel() {
        lock.withLock { cancelled = true }
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
