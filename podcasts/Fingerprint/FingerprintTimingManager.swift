import Foundation
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

    var generator: FingerprintGenerator?

    // MARK: - Internal Types

    private struct GenerationContext {
        let episodeUuid: String
        let reference: ReferenceFingerprint
        let audioFileURL: URL
        let fileSize: UInt64
        let duration: Double
        let generator: FingerprintGenerator
        let cancellationToken: FingerprintCancellationToken
    }

    private struct TimeMappingEntry {
        let playbackTime: Double
        let referenceTime: Double
    }

    // MARK: - Private State

    private let queue = DispatchQueue(label: "au.com.pocketcasts.FingerprintTimingManager")
    private var context: GenerationContext?
    private var playbackToReference: [TimeMappingEntry] = []
    private var referenceToPlayback: [TimeMappingEntry] = []
    private var lastPlaybackTime: Double = -1
    private var lastProcessedBatchIndex: Int = -1
    private var isProcessingBatch = false

    // MARK: - Init

    override init() {
        super.init()
    }

    // MARK: - Lifecycle

    func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackChanged),
            name: Constants.Notifications.playbackTrackChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackProgress),
            name: Constants.Notifications.playbackProgress,
            object: nil
        )
        FileLog.shared.addMessage("FingerprintTimingManager: setup complete")
    }

    // MARK: - Public API

    func referenceTime(forPlaybackTime playbackTime: Double) -> Double? {
        queue.sync {
            Self.interpolate(
                time: playbackTime,
                in: playbackToReference,
                keyPath: \.playbackTime,
                valuePath: \.referenceTime
            )
        }
    }

    func playbackTime(forReferenceTime referenceTime: Double) -> Double? {
        queue.sync {
            Self.interpolate(
                time: referenceTime,
                in: referenceToPlayback,
                keyPath: \.referenceTime,
                valuePath: \.playbackTime
            )
        }
    }

    // MARK: - Notification Handlers

    @objc private func handleTrackChanged() {
        let episode = PlaybackManager.shared.currentEpisode()
        let gen = generator

        queue.async { [weak self] in
            guard let self else { return }
            self.resetState()
            self.prepareForEpisode(episode, generator: gen)
        }
    }

    @objc private func handlePlaybackProgress() {
        let playbackTime = PlaybackManager.shared.currentTime()
        guard playbackTime >= 0 else { return }

        let episodeUuid = PlaybackManager.shared.currentEpisode()?.uuid

        queue.async { [weak self] in
            self?.processProgress(playbackTime: playbackTime, episodeUuid: episodeUuid)
        }
    }

    // MARK: - State Management

    private func resetState() {
        context?.cancellationToken.cancel()
        context = nil
        playbackToReference.removeAll()
        referenceToPlayback.removeAll()
        lastPlaybackTime = -1
        lastProcessedBatchIndex = -1
        isProcessingBatch = false
    }

    private func updateState(_ newState: State) {
        DispatchQueue.main.async { [weak self] in
            self?.state = newState
        }
    }

    // MARK: - Track Preparation

    private func prepareForEpisode(_ episode: BaseEpisode?, generator: FingerprintGenerator?) {
        updateState(.idle)

        guard let episode else {
            updateState(.unavailable)
            return
        }

        guard let generator else {
            updateState(.unavailable)
            FileLog.shared.addMessage("FingerprintTimingManager: no generator configured")
            return
        }

        let uuid = episode.uuid

        guard let reference = loadReference(for: episode) else {
            updateState(.unavailable)
            FileLog.shared.addMessage("FingerprintTimingManager: no reference fingerprint for \(uuid)")
            return
        }

        guard let audioFileURL = resolveAudioFileURL(for: episode) else {
            updateState(.unavailable)
            FileLog.shared.addMessage("FingerprintTimingManager: no audio file for \(uuid)")
            return
        }

        let fileSize: UInt64
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: audioFileURL.path)
            fileSize = attrs[.size] as? UInt64 ?? 0
        } catch {
            updateState(.failed(error))
            FileLog.shared.addMessage("FingerprintTimingManager: cannot read file attributes — \(error.localizedDescription)")
            return
        }

        let duration = episode.duration
        guard fileSize > 0, duration > 0 else {
            updateState(.unavailable)
            return
        }

        let newContext = GenerationContext(
            episodeUuid: uuid,
            reference: reference,
            audioFileURL: audioFileURL,
            fileSize: fileSize,
            duration: duration,
            generator: generator,
            cancellationToken: FingerprintCancellationToken()
        )
        context = newContext

        updateState(.preparing)
        FileLog.shared.addMessage(
            "FingerprintTimingManager: preparing for \(uuid) (\(reference.checkpoints.count) checkpoints)"
        )
    }

    // MARK: - Progress Processing

    private func processProgress(playbackTime: Double, episodeUuid: String?) {
        guard let ctx = context, ctx.episodeUuid == episodeUuid else { return }

        if lastPlaybackTime >= 0 {
            let delta = abs(playbackTime - lastPlaybackTime)
            if delta > FingerprintConstants.restartDeltaSeconds {
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: jump detected (\(String(format: "%.1f", delta))s), restarting"
                )
                restartFromCurrentPosition(playbackTime: playbackTime)
                return
            }
        }
        lastPlaybackTime = playbackTime

        if isWithinMappedRange(playbackTime) { return }
        guard !isProcessingBatch else { return }

        let batchDur = batchDuration(for: ctx.reference)
        guard batchDur > 0 else { return }
        let batchIndex = Int(playbackTime / batchDur)
        guard batchIndex != lastProcessedBatchIndex else { return }

        lastProcessedBatchIndex = batchIndex
        isProcessingBatch = true

        generateAndMatchBatch(batchIndex: batchIndex, context: ctx)
    }

    private func restartFromCurrentPosition(playbackTime: Double) {
        playbackToReference.removeAll()
        referenceToPlayback.removeAll()
        lastProcessedBatchIndex = -1
        isProcessingBatch = false
        lastPlaybackTime = playbackTime
        updateState(.preparing)
    }

    private func isWithinMappedRange(_ playbackTime: Double) -> Bool {
        guard let first = playbackToReference.first,
              let last = playbackToReference.last else {
            return false
        }
        let margin = FingerprintConstants.playbackRangeMarginSeconds
        return playbackTime >= first.playbackTime - margin
            && playbackTime <= last.playbackTime + margin
    }

    // MARK: - Batch Generation & Matching

    private func batchDuration(for reference: ReferenceFingerprint) -> Double {
        let intervalSeconds = Double(reference.checkpointInterval) * Double(reference.timestampQuantum) / 1000.0
        return Double(FingerprintConstants.batchSize) * intervalSeconds
    }

    private func generateAndMatchBatch(batchIndex: Int, context ctx: GenerationContext) {
        let batchDur = batchDuration(for: ctx.reference)
        let startTime = Double(batchIndex) * batchDur
        let endTime = min(startTime + batchDur, ctx.duration)

        let bytesPerSecond = Double(ctx.fileSize) / ctx.duration
        let startByte = UInt64(max(0, startTime * bytesPerSecond))
        let endByte = min(UInt64(endTime * bytesPerSecond), ctx.fileSize)

        guard startByte < endByte else {
            isProcessingBatch = false
            return
        }

        ctx.generator.generate(
            for: ctx.audioFileURL,
            byteRange: startByte..<endByte,
            cancellationToken: ctx.cancellationToken
        ) { [weak self] result in
            guard let self else { return }

            self.queue.async {
                defer { self.isProcessingBatch = false }
                guard self.context?.episodeUuid == ctx.episodeUuid else { return }

                switch result {
                case .success(let windowFingerprint):
                    self.processMatches(
                        windowFingerprint: windowFingerprint,
                        windowStartTime: startTime,
                        context: ctx
                    )
                case .failure(let error):
                    FileLog.shared.addMessage(
                        "FingerprintTimingManager: batch \(batchIndex) failed — \(error)"
                    )
                }
            }
        }
    }

    private func processMatches(
        windowFingerprint: ReferenceFingerprint,
        windowStartTime: Double,
        context ctx: GenerationContext
    ) {
        let matches = CheckpointMatcher.findTopMatches(
            windowFingerprint: windowFingerprint,
            reference: ctx.reference
        )

        guard let bestMatch = matches.first else {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: no matches for window at \(String(format: "%.1f", windowStartTime))s"
            )
            return
        }

        let quantum = ctx.reference.timestampQuantum
        let windowTimes = Self.absoluteTimes(for: windowFingerprint.checkpoints, quantum: quantum)
        let refTimes = Self.absoluteTimes(for: ctx.reference.checkpoints, quantum: quantum)

        let startIdx = bestMatch.referenceStartIndex
        for i in 0..<windowFingerprint.checkpoints.count {
            let refIdx = startIdx + i
            guard refIdx < refTimes.count, i < windowTimes.count else { break }

            insertMapping(TimeMappingEntry(
                playbackTime: windowStartTime + windowTimes[i],
                referenceTime: refTimes[refIdx]
            ))
        }

        let coverage = playbackToReference.count
        if coverage >= FingerprintConstants.minimumCoverageForActive {
            updateState(.active(coverage: coverage))
        }

        FileLog.shared.addMessage(
            "FingerprintTimingManager: matched at \(String(format: "%.1f", windowStartTime))s "
                + "(score: \(String(format: "%.2f", bestMatch.score)), coverage: \(coverage))"
        )
    }

    // MARK: - Time Mapping

    private func insertMapping(_ entry: TimeMappingEntry) {
        let pbIdx = playbackToReference.sortedInsertionIndex { $0.playbackTime < entry.playbackTime }
        playbackToReference.insert(entry, at: pbIdx)

        let refIdx = referenceToPlayback.sortedInsertionIndex { $0.referenceTime < entry.referenceTime }
        referenceToPlayback.insert(entry, at: refIdx)
    }

    private static func interpolate(
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

    private static func absoluteTimes(
        for checkpoints: [ReferenceFingerprint.Checkpoint],
        quantum: Int
    ) -> [Double] {
        var times: [Double] = []
        var accumulated = 0
        for checkpoint in checkpoints {
            accumulated += checkpoint.delta
            times.append(Double(accumulated) * Double(quantum) / 1000.0)
        }
        return times
    }

    private func loadReference(for episode: BaseEpisode) -> ReferenceFingerprint? {
        let audioPath = DownloadManager.shared.pathForEpisode(episode)
        let fpPath = (audioPath as NSString).deletingPathExtension + ".fp.json"
        guard let data = FileManager.default.contents(atPath: fpPath) else { return nil }
        return ReferenceFingerprint.decode(from: data)
    }

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
