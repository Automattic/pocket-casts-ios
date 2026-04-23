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

    // MARK: - Public Properties

    private(set) var state: State = .idle

    // MARK: - Internal Types

    private struct GenerationContext {
        let episodeUuid: String
        let audioFileURL: URL
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
    private var context: GenerationContext?
    private var cancellationFlag = CancellationFlag()
    private var fetchTask: Task<Void, Never>?
    private var playbackToReference: [TimeMappingEntry] = []
    private var referenceToPlayback: [TimeMappingEntry] = []
    private var lastProgressPosition: Double = -1

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

        if lastProgressPosition >= 0 {
            let delta = abs(playbackTime - lastProgressPosition)
            if delta > FingerprintConstants.restartDeltaSeconds {
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: playback jumped \(String(format: "%.1f", delta))s — restarting from \(String(format: "%.1f", playbackTime))s"
                )
                restart(from: playbackTime, context: ctx)
                lastProgressPosition = playbackTime
                return
            }
        }
        lastProgressPosition = playbackTime

        if isWithinMappedRange(playbackTime) { return }
        FileLog.shared.addMessage(
            "FingerprintTimingManager: playback at \(String(format: "%.1f", playbackTime))s outside mapped range — restarting"
        )
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
            self?.state = newState
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

        if let reference = loadReference(for: episode) {
            configureForReference(reference, episode: episode)
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
                self.configureForReference(reference, episode: episode)
            }
        }
    }

    private func configureForReference(_ reference: ReferenceFingerprint, episode: BaseEpisode) {
        let uuid = episode.uuid

        guard let audioFileURL = resolveAudioFileURL(for: episode) else {
            updateState(.unavailable)
            FileLog.shared.addMessage("FingerprintTimingManager: no local audio file for \(uuid) — skipping fingerprinting")
            return
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
            duration: duration,
            matcher: matcher,
            isCancelled: { flag.isCancelled }
        )
        context = newContext

        updateState(.preparing)
        FileLog.shared.addMessage(
            "FingerprintTimingManager: preparing for \(uuid) (\(libraryCheckpoints.count) checkpoints)"
        )

        let startPosition = PlaybackManager.shared.currentTime()
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
                try self.streamFingerprint(context: ctx, startingAt: aligned)
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming fingerprint completed (started at \(String(format: "%.1f", aligned))s)"
                )
                self.finishIfStillPreparing(terminalState: .unavailable, context: ctx)
            } catch StreamError.cancelled {
                FileLog.shared.addMessage("FingerprintTimingManager: streaming fingerprint cancelled")
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

        while true {
            if ctx.isCancelled() { throw StreamError.cancelled }
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
        var bestScoreOverall: Float = 0
        var nonZeroScoreCount = 0
        var scoreSum: Float = 0

        for window in windows {
            let matches = ctx.matcher.findTopMatches(
                queryHashes: window.hashes,
                maxResults: 1
            )
            if let best = matches.first {
                if best.score > 0 {
                    nonZeroScoreCount += 1
                    scoreSum += best.score
                }
                if best.score > bestScoreOverall { bestScoreOverall = best.score }

                if best.score >= FingerprintConstants.matchScoreThreshold {
                    let absolutePlaybackTime = startOffset + Double(window.timestampMs) / 1000.0
                    let candidate = TimeMappingEntry(
                        playbackTime: absolutePlaybackTime,
                        referenceTime: Double(best.timestamp),
                        score: best.score
                    )
                    inserted += consider(candidate: candidate)
                }
            }
        }

        let coverage = playbackToReference.count
        if coverage >= FingerprintConstants.minimumCoverageForActive {
            updateState(.active(coverage: coverage))
        }

        let avgNonZero = nonZeroScoreCount > 0 ? scoreSum / Float(nonZeroScoreCount) : 0
        FileLog.shared.addMessage(
            "FingerprintTimingManager: matched \(inserted)/\(windows.count) windows "
                + "(coverage: \(coverage), bestScore: \(String(format: "%.3f", bestScoreOverall)), "
                + "nonZero: \(nonZeroScoreCount), avgNonZero: \(String(format: "%.3f", avgNonZero)))"
        )
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
            FileLog.shared.addMessage(
                "FingerprintTimingManager: drift filter confirmed anchor "
                    + "at playback \(String(format: "%.1f", recent.first!.playbackTime))s → "
                    + "\(String(format: "%.1f", recent.last!.playbackTime))s "
                    + "(\(n) consistent)"
            )
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
        FileLog.shared.addMessage(
            "FingerprintTimingManager: drift filter dropped \(reason) "
                + "at playback \(String(format: "%.1f", entry.playbackTime))s "
                + "(matched reference \(String(format: "%.1f", entry.referenceTime))s)"
        )
        #if DEBUG
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

    private func loadReference(for episode: BaseEpisode) -> ReferenceFingerprint? {
        let path = referencePath(for: episode)
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        return ReferenceFingerprint.decode(from: data)
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

    /// Resolves the local audio file for an episode. The downloaded path is always
    /// a complete file. The streaming-buffer path may still be growing — `AVAudioFile`
    /// only sees the bytes present at open time, so we'll fingerprint up to that point
    /// and stop; the rest of the buffer (if it fills in later) is not picked up. Full
    /// streaming support would need file-growth tracking, which is out of scope for
    /// this PR (see `bufferGrowPollCadenceSeconds` in `FingerprintConstants`).
    private func resolveAudioFileURL(for episode: BaseEpisode) -> URL? {
        let downloadPath = DownloadManager.shared.pathForEpisode(episode)
        if FileManager.default.fileExists(atPath: downloadPath) {
            return URL(fileURLWithPath: downloadPath)
        }
        let streamingPath = DownloadManager.shared.streamingBufferPathForEpisode(episode)
        if FileManager.default.fileExists(atPath: streamingPath) {
            return URL(fileURLWithPath: streamingPath)
        }
        return nil
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
