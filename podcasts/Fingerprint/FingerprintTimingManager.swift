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
        let fingerprinter: Fingerprinter
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

    // MARK: - Init

    override init() {
        super.init()
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
            FileLog.shared.addMessage("FingerprintTimingManager: episode \(uuid) is not downloaded — skipping fingerprinting")
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
            fingerprinter: Fingerprinter(),
            isCancelled: { flag.isCancelled }
        )
        context = newContext

        updateState(.preparing)
        FileLog.shared.addMessage(
            "FingerprintTimingManager: preparing for \(uuid) (\(libraryCheckpoints.count) checkpoints)"
        )

        processAllBatches(context: newContext)
    }

    // MARK: - Full-File Processing

    /// Fingerprint the whole downloaded file in one pass. We can't byte-slice and feed
    /// arbitrary chunks to the fingerprinter — the codec needs a real container/header
    /// to detect format, which only exists at file start. Memory-mapping the file keeps
    /// peak resident memory bounded.
    private func processAllBatches(context ctx: GenerationContext) {
        generationQueue.async { [weak self] in
            guard let self else { return }
            let result = Self.fingerprintWholeFile(
                fileURL: ctx.audioFileURL,
                fingerprinter: ctx.fingerprinter,
                isCancelled: ctx.isCancelled
            )

            self.queue.async { [weak self] in
                guard let self, self.context?.episodeUuid == ctx.episodeUuid else { return }

                switch result {
                case .success(let windows):
                    self.processMatches(windows: windows, context: ctx)
                    FileLog.shared.addMessage(
                        "FingerprintTimingManager: full-file processing completed (\(windows.count) windows)"
                    )
                case .failure(let error):
                    FileLog.shared.addMessage(
                        "FingerprintTimingManager: full-file processing failed — \(error)"
                    )
                }
            }
        }
    }

    private static func fingerprintWholeFile(
        fileURL: URL,
        fingerprinter: Fingerprinter,
        isCancelled: () -> Bool
    ) -> Result<[WindowedFingerprint], Error> {
        if isCancelled() { return .failure(BatchError.cancelled) }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        } catch {
            return .failure(error)
        }

        if isCancelled() { return .failure(BatchError.cancelled) }

        do {
            let windows = try fingerprinter.fingerprintDataWindowed(
                data: data,
                windowDurationMs: FingerprintConstants.windowDurationMs,
                windowIntervalMs: FingerprintConstants.windowIntervalMs
            )
            return .success(windows)
        } catch {
            return .failure(error)
        }
    }

    private enum BatchError: Error {
        case cancelled
    }

    private func processMatches(
        windows: [WindowedFingerprint],
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
                    insertMapping(TimeMappingEntry(
                        playbackTime: Double(window.timestampMs) / 1000.0,
                        referenceTime: Double(best.timestamp),
                        score: best.score
                    ))
                    inserted += 1
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

    // MARK: - Time Mapping

    /// Test seam: inserts a mapping on the manager's serial queue so queries are
    /// consistent with production insertions that happen from within `processMatches`.
    func insert(mapping: TimeMappingEntry) {
        queue.sync { insertMapping(mapping) }
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

    /// Downloaded-only: the full-file processing path requires the complete audio file on disk.
    /// Streaming-buffer support is intentionally out of scope for POC-531.
    private func resolveAudioFileURL(for episode: BaseEpisode) -> URL? {
        let downloadPath = DownloadManager.shared.pathForEpisode(episode)
        guard FileManager.default.fileExists(atPath: downloadPath) else { return nil }
        return URL(fileURLWithPath: downloadPath)
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
