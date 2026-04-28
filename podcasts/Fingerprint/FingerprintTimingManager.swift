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
    }

    // MARK: - Singleton

    static let shared = FingerprintTimingManager()

    /// Posted on the main queue whenever `state` transitions. Subscribers can
    /// avoid polling and only do work when the manager actually has (or loses)
    /// a usable mapping — used to gate the transcript view's CADisplayLink.
    static let stateDidChange = NSNotification.Name("FingerprintTimingManagerStateDidChange")

    // MARK: - Public Properties

    private(set) var state: State = .idle

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
    /// Separate queue for tap-to-seek probes so they don't sit behind the
    /// long-running live stream loop on `generationQueue`. `userInitiated`
    /// because the probe is the seek's critical path — the user is waiting.
    private let probeQueue = DispatchQueue(
        label: "au.com.pocketcasts.FingerprintTimingManager.probe",
        qos: .userInitiated
    )
    private var context: GenerationContext?
    private var cancellationFlag = CancellationFlag()
    private var fetchTask: Task<Void, Never>?
    private var playbackToReference: [TimeMappingEntry] = []
    private var referenceToPlayback: [TimeMappingEntry] = []
    private var lastProgressPosition: Double = -1
    private var currentReferenceData: Data?
    private var lastCacheSave: Date?
    private static let cacheSaveDebounceSeconds: TimeInterval = 5

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
            self.saveCacheIfNeeded(force: true)
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

    /// Tap-to-seek resolver. Decodes a window of the local audio around the
    /// cue's estimated playback position, fingerprints it, asks the matcher
    /// what reference content that audio actually contains, and returns the
    /// playback time of the window whose match is closest to `referenceTime`.
    /// The existing playback↔reference mapping is *not* consulted — linear
    /// interpolation across sparse anchors masks ad-insertion discontinuities
    /// and lands the seek in the wrong place. Resolves with `nil` when the
    /// audio at the guess position doesn't yield a confident match near the
    /// tapped cue. Always calls `completion` on the main queue. `tag` is a
    /// short id propagated through every log line so a single tap's trace
    /// can be grepped by key.
    func resolvePlaybackTime(
        forReferenceTime referenceTime: Double,
        tag: String,
        completion: @escaping (Double?) -> Void
    ) {
        queue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            FileLog.shared.addMessage(
                "[tap-to-seek \(tag)] resolve targetRef="
                    + "\(String(format: "%.2f", referenceTime))s"
            )
            guard let ctx = self.context, !ctx.isStreaming else {
                FileLog.shared.addMessage(
                    "[tap-to-seek \(tag)] no probe context "
                        + "(context=\(self.context != nil), "
                        + "isStreaming=\(self.context?.isStreaming ?? false)) — giving up"
                )
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self.runProbe(
                targetReferenceTime: referenceTime,
                context: ctx,
                tag: tag,
                completion: completion
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
        currentReferenceData = nil
        lastCacheSave = nil
        resetFilterState()
        #if DEBUG
        debugRejections.removeAll()
        #endif
    }

    private func resetFilterState() {
        filterLastTrusted = nil
        filterCandidatePool.removeAll()
    }

    private func updateState(_ newState: State) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.state = newState
            NotificationCenter.default.post(name: Self.stateDidChange, object: self)
        }
    }

    // MARK: - Track Preparation

    private func prepareForEpisode(_ episode: BaseEpisode?) {
        updateState(.idle)

        guard FeatureFlag.syncedTranscripts.enabled else {
            updateState(.unavailable)
            return
        }

        guard let episode else {
            updateState(.unavailable)
            return
        }

        let uuid = episode.uuid

        if let (reference, referenceData) = loadReference(for: episode) {
            configureForReference(reference, referenceData: referenceData, episode: episode)
            return
        }

        updateState(.preparing)
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
        let newContext = GenerationContext(
            episodeUuid: uuid,
            audioFileURL: audioFileURL,
            isStreaming: isStreaming,
            duration: duration,
            matcher: matcher,
            isCancelled: { flag.isCancelled }
        )
        context = newContext
        currentReferenceData = referenceData

        updateState(.preparing)
        FileLog.shared.addMessage(
            "FingerprintTimingManager: preparing for \(uuid) (\(libraryCheckpoints.count) checkpoints)"
        )

        let startPosition = PlaybackManager.shared.currentTime()

        // Cache short-circuit: for fully-downloaded audio, seed any previously
        // committed mappings from disk. The drift-filter anchor picks up where
        // we left off so a re-stream after a seek extends the existing trend.
        // Skip the live stream only when the cache has enough coverage to be
        // .active AND playback is inside that coverage — otherwise we'd sit in
        // .preparing forever with a partial mapping the transcript view can't
        // use. Below threshold, kick the stream regardless so coverage grows.
        if !isStreaming, !FingerprintConstants.eagerFingerprintingEnabled,
           let cached = FingerprintMappingCache.load(
               audioFilePath: audioFileURL.path,
               referenceData: referenceData
           ) {
            for entry in cached {
                insertMapping(entry)
            }
            filterLastTrusted = cached.last
            let coverage = playbackToReference.count
            let reachedActive = coverage >= FingerprintConstants.minimumCoverageForActive
            if reachedActive {
                updateState(.active(coverage: coverage))
            }
            FileLog.shared.addMessage(
                "FingerprintTimingManager: cache hit for \(uuid) — seeded \(coverage) mappings"
            )
            if reachedActive, isWithinMappedRange(startPosition) {
                return
            }
            FileLog.shared.addMessage(
                "FingerprintTimingManager: cache coverage \(coverage) "
                    + "(active=\(reachedActive), inRange=\(isWithinMappedRange(startPosition))) "
                    + "— starting stream from \(String(format: "%.1f", startPosition))s"
            )
        }

        startStream(context: newContext, fromPosition: startPosition)
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
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if case .active = self.state { return }
                self.state = terminalState
                NotificationCenter.default.post(name: Self.stateDidChange, object: self)
            }
        }
    }

    /// Snap a playback time to the window-interval grid so that the windows we
    /// emit align with the reference checkpoint timestamps. The reference is
    /// produced with the same `windowIntervalMs` stride starting at 0, so any
    /// off-grid start would yield windows whose audio content is shifted
    /// relative to the reference and would fail to match.
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

        var wasGated = false
        while true {
            if ctx.isCancelled() { throw StreamError.cancelled }

            if try waitForLookaheadRoom(
                nextChunkStartSeconds: Double(audioFile.framePosition) / format.sampleRate,
                context: ctx,
                wasGated: &wasGated
            ) {
                continue
            }

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
        var wasGated = false

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

            if try waitForLookaheadRoom(
                nextChunkStartSeconds: Double(lastProcessedFrame) / fmt.sampleRate,
                context: ctx,
                wasGated: &wasGated
            ) {
                continue
            }

            audioFile.framePosition = lastProcessedFrame
            let framesAvailable = AVAudioFrameCount(safeEnd - lastProcessedFrame)
            let framesToRead = min(framesAvailable, chunkFrames)

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

    /// Returns `true` if the caller should `continue` its loop — i.e. we slept
    /// because the next chunk is too far ahead of where the listener is. The
    /// gate keeps the streaming fingerprint loop within `lookaheadSeconds` of
    /// `PlaybackManager.currentTime()` so we don't fingerprint material the
    /// listener may never reach. Bypassed when `eagerFingerprintingEnabled`.
    /// Logs only on entry/exit (`wasGated` toggle) to avoid log spam during
    /// long pauses.
    private func waitForLookaheadRoom(
        nextChunkStartSeconds: Double,
        context ctx: GenerationContext,
        wasGated: inout Bool
    ) throws -> Bool {
        if FingerprintConstants.eagerFingerprintingEnabled { return false }

        let currentPlayback = PlaybackManager.shared.currentTime()
        guard currentPlayback >= 0 else { return false }

        let lead = nextChunkStartSeconds - currentPlayback
        if lead > FingerprintConstants.lookaheadSeconds {
            if !wasGated {
                wasGated = true
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: lookahead reached "
                        + "(next chunk @ \(String(format: "%.1f", nextChunkStartSeconds))s, "
                        + "playback @ \(String(format: "%.1f", currentPlayback))s, "
                        + "lead \(String(format: "%.1f", lead))s) — sleeping until playback catches up"
                )
            }
            try sleepWithCancellation(seconds: 1.0, context: ctx)
            return true
        }

        if wasGated {
            wasGated = false
            FileLog.shared.addMessage(
                "FingerprintTimingManager: lookahead room available again "
                    + "(playback @ \(String(format: "%.1f", currentPlayback))s) — resuming"
            )
        }
        return false
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
        }

        if inserted > 0 {
            saveCacheIfNeeded(force: false)
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

    private func loadReference(for episode: BaseEpisode) -> (ReferenceFingerprint, Data)? {
        let path = referencePath(for: episode)
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        guard let reference = ReferenceFingerprint.decode(from: data) else { return nil }
        return (reference, data)
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

    /// Persist the current `playbackToReference` mapping to disk so the next
    /// transcript open of this downloaded episode can skip the audio decode +
    /// match work. Debounced to avoid I/O on every batch; called with
    /// `force: true` from `stop()` to flush before tear-down.
    /// Streaming buffers are skipped — they may be partial, deleted, or
    /// resized, so caching their mappings is not worth the validation cost.
    private func saveCacheIfNeeded(force: Bool) {
        guard let ctx = context, !ctx.isStreaming else { return }
        guard let referenceData = currentReferenceData else { return }
        guard !playbackToReference.isEmpty else { return }
        if !force, let last = lastCacheSave,
           Date().timeIntervalSince(last) < Self.cacheSaveDebounceSeconds {
            return
        }
        FingerprintMappingCache.save(
            playbackToReference,
            audioFilePath: ctx.audioFileURL.path,
            referenceData: referenceData
        )
        lastCacheSave = Date()
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

    // MARK: - Tap-to-Seek Probe

    private struct ProbeResult {
        let playbackTime: Double
        let referenceTime: Double
        let score: Float
    }

    /// How many seconds of audio the probe decodes, centered on the guess
    /// position. Long enough to absorb ad-shifts of up to ~half this
    /// value in either direction, short enough that the wall-clock wait
    /// stays imperceptible on modern hardware.
    private static let probeDurationSeconds: Double = 120

    /// Maximum acceptable distance between a probe candidate's reference
    /// time and the user's target. Wider than `driftToleranceSeconds`
    /// because the probe is searching across an unknown ad shift; we only
    /// need to confirm the candidate landed in the same neighborhood as
    /// the tapped cue, not that it pinpoints it.
    private static let probeMatchWindowSeconds: Double = 90

    private func runProbe(
        targetReferenceTime: Double,
        context ctx: GenerationContext,
        tag: String,
        completion: @escaping (Double?) -> Void
    ) {
        // Center the scan on a 1:1 guess for the cue's playback time. With
        // a symmetric window we catch the cue regardless of which way the
        // audio shifted (ads added past the cue, or intro trimmed before).
        // Clamped to the file bounds; near the start the scan slides
        // forward, near the end it slides backward.
        let halfDuration = Self.probeDurationSeconds / 2
        let raw = max(0, min(ctx.duration - Self.probeDurationSeconds, targetReferenceTime - halfDuration))
        let probeStart = Self.alignToWindowGrid(raw)
        let audioFileURL = ctx.audioFileURL
        let matcher = ctx.matcher

        probeQueue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            FileLog.shared.addMessage(
                "[tap-to-seek \(tag)] probe start "
                    + "targetRef=\(String(format: "%.2f", targetReferenceTime))s "
                    + "guessPlayback=\(String(format: "%.2f", probeStart))s "
                    + "duration=\(String(format: "%.2f", ctx.duration))s "
                    + "file=\(audioFileURL.lastPathComponent)"
            )
            let result = self.probeAudio(
                audioFileURL: audioFileURL,
                startSeconds: probeStart,
                targetReferenceTime: targetReferenceTime,
                matcher: matcher,
                tag: tag
            )
            if let result {
                FileLog.shared.addMessage(
                    "[tap-to-seek \(tag)] probe accepted "
                        + "ref=\(String(format: "%.2f", result.referenceTime))s "
                        + "→ playback=\(String(format: "%.2f", result.playbackTime))s "
                        + "score=\(String(format: "%.3f", result.score))"
                )
                self.queue.async { [weak self] in
                    self?.insertMapping(TimeMappingEntry(
                        playbackTime: result.playbackTime,
                        referenceTime: result.referenceTime,
                        score: result.score
                    ))
                }
            } else {
                FileLog.shared.addMessage(
                    "[tap-to-seek \(tag)] probe failed — no confident match near "
                        + "\(String(format: "%.2f", targetReferenceTime))s"
                )
            }
            DispatchQueue.main.async { completion(result?.playbackTime) }
        }
    }

    private func probeAudio(
        audioFileURL: URL,
        startSeconds: Double,
        targetReferenceTime: Double,
        matcher: CheckpointMatcher,
        tag: String
    ) -> ProbeResult? {
        do {
            let audioFile = try AVAudioFile(
                forReading: audioFileURL,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
            let format = audioFile.processingFormat
            let startFrame = AVAudioFramePosition(startSeconds * format.sampleRate)
            guard startFrame >= 0, startFrame < audioFile.length else {
                FileLog.shared.addMessage(
                    "[tap-to-seek \(tag)] probe out-of-range "
                        + "startFrame=\(startFrame) audioLength=\(audioFile.length)"
                )
                return nil
            }
            audioFile.framePosition = startFrame

            let streamer = StreamingWindowedFingerprinter(
                sampleRate: UInt32(format.sampleRate),
                channels: UInt16(format.channelCount),
                windowDurationMs: FingerprintConstants.windowDurationMs,
                windowIntervalMs: FingerprintConstants.windowIntervalMs
            )

            let chunkFrames = AVAudioFrameCount(format.sampleRate * FingerprintConstants.streamChunkSeconds)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrames) else {
                return nil
            }

            let endFrame = startFrame + AVAudioFramePosition(Self.probeDurationSeconds * format.sampleRate)
            var candidates: [TimeMappingEntry] = []
            var windowsSeen = 0
            var rejectedLowScore = 0
            var rejectedAmbiguous = 0
            var rejectedNoMatch = 0

            while audioFile.framePosition < endFrame, audioFile.framePosition < audioFile.length {
                try audioFile.read(into: buffer, frameCount: chunkFrames)
                if buffer.frameLength == 0 { break }
                let interleaved = Self.interleavedSamples(from: buffer)
                let windows = streamer.pushSamplesF32(samples: interleaved, channels: UInt16(format.channelCount))
                windowsSeen += windows.count
                Self.collectProbeCandidates(
                    windows: windows,
                    startSeconds: startSeconds,
                    matcher: matcher,
                    into: &candidates,
                    rejectedLowScore: &rejectedLowScore,
                    rejectedAmbiguous: &rejectedAmbiguous,
                    rejectedNoMatch: &rejectedNoMatch
                )
            }
            let tail = streamer.flush()
            windowsSeen += tail.count
            Self.collectProbeCandidates(
                windows: tail,
                startSeconds: startSeconds,
                matcher: matcher,
                into: &candidates,
                rejectedLowScore: &rejectedLowScore,
                rejectedAmbiguous: &rejectedAmbiguous,
                rejectedNoMatch: &rejectedNoMatch
            )

            FileLog.shared.addMessage(
                "[tap-to-seek \(tag)] probe windows=\(windowsSeen) "
                    + "accepted=\(candidates.count) "
                    + "rejected[low=\(rejectedLowScore), ambig=\(rejectedAmbiguous), none=\(rejectedNoMatch)]"
            )
            for (i, c) in candidates.prefix(20).enumerated() {
                FileLog.shared.addMessage(
                    "[tap-to-seek \(tag)] cand[\(i)] "
                        + "playback=\(String(format: "%.2f", c.playbackTime))s "
                        + "ref=\(String(format: "%.2f", c.referenceTime))s "
                        + "score=\(String(format: "%.3f", c.score))"
                )
            }

            return Self.bestProbeMatch(in: candidates, near: targetReferenceTime, tag: tag)
        } catch {
            FileLog.shared.addMessage(
                "[tap-to-seek \(tag)] probe error — \(error.localizedDescription)"
            )
            return nil
        }
    }

    private static func collectProbeCandidates(
        windows: [WindowedFingerprint],
        startSeconds: Double,
        matcher: CheckpointMatcher,
        into candidates: inout [TimeMappingEntry],
        rejectedLowScore: inout Int,
        rejectedAmbiguous: inout Int,
        rejectedNoMatch: inout Int
    ) {
        for window in windows {
            let matches = matcher.findTopMatches(queryHashes: window.hashes, maxResults: 2)
            guard let best = matches.first else {
                rejectedNoMatch += 1
                continue
            }
            guard best.score >= FingerprintConstants.driftAnchorScoreThreshold else {
                rejectedLowScore += 1
                continue
            }
            let runnerUpScore = matches.dropFirst().first?.score ?? 0
            guard best.score - runnerUpScore >= FingerprintConstants.driftScoreDominanceGap else {
                rejectedAmbiguous += 1
                continue
            }
            candidates.append(TimeMappingEntry(
                playbackTime: startSeconds + Double(window.timestampMs) / 1000.0,
                referenceTime: Double(best.timestamp),
                score: best.score
            ))
        }
    }

    /// From the probe's collected candidates, pick the one closest to
    /// `targetReferenceTime` that's part of a `driftBootstrapCount`-length
    /// rate-1 consistent run. Symmetric scans can produce *multiple* runs
    /// separated by an ad break, so we don't just pick the longest run —
    /// we pick the trusted candidate with the smallest reference-time
    /// distance to the user's target. The match must land within
    /// `probeMatchWindowSeconds` to be accepted.
    private static func bestProbeMatch(
        in candidates: [TimeMappingEntry],
        near targetReferenceTime: Double,
        tag: String
    ) -> ProbeResult? {
        let sorted = candidates.sorted { $0.playbackTime < $1.playbackTime }
        guard sorted.count >= FingerprintConstants.driftBootstrapCount else {
            FileLog.shared.addMessage(
                "[tap-to-seek \(tag)] not enough candidates "
                    + "(\(sorted.count) < \(FingerprintConstants.driftBootstrapCount))"
            )
            return nil
        }

        var runs: [[TimeMappingEntry]] = []
        var current: [TimeMappingEntry] = []
        for candidate in sorted {
            if let last = current.last, !isInTrend(candidate, relativeTo: last) {
                if current.count >= FingerprintConstants.driftBootstrapCount {
                    runs.append(current)
                }
                current = []
            }
            current.append(candidate)
        }
        if current.count >= FingerprintConstants.driftBootstrapCount {
            runs.append(current)
        }

        guard !runs.isEmpty else {
            FileLog.shared.addMessage(
                "[tap-to-seek \(tag)] no consistent run of "
                    + "\(FingerprintConstants.driftBootstrapCount)"
            )
            return nil
        }

        let trusted = runs.flatMap { $0 }
        let closest = trusted.min(by: {
            abs($0.referenceTime - targetReferenceTime) < abs($1.referenceTime - targetReferenceTime)
        })!
        let delta = abs(closest.referenceTime - targetReferenceTime)

        let runSummary = runs.enumerated().map { idx, run in
            "run\(idx)[len=\(run.count), "
                + "ref=\(String(format: "%.2f", run.first!.referenceTime))..\(String(format: "%.2f", run.last!.referenceTime))s]"
        }.joined(separator: " ")
        FileLog.shared.addMessage(
            "[tap-to-seek \(tag)] runs=\(runs.count) trusted=\(trusted.count) \(runSummary) "
                + "closest ref=\(String(format: "%.2f", closest.referenceTime))s "
                + "playback=\(String(format: "%.2f", closest.playbackTime))s "
                + "Δ=\(String(format: "%.2f", delta))s"
        )

        guard delta <= probeMatchWindowSeconds else {
            FileLog.shared.addMessage(
                "[tap-to-seek \(tag)] closest Δ=\(String(format: "%.2f", delta))s "
                    + "> max=\(String(format: "%.2f", probeMatchWindowSeconds))s — rejecting"
            )
            return nil
        }
        return ProbeResult(
            playbackTime: closest.playbackTime,
            referenceTime: closest.referenceTime,
            score: closest.score
        )
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
