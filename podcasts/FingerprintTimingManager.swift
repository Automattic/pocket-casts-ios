import Foundation
import Fingerprint
import PocketCastsDataModel

class FingerprintTimingManager {
    static let shared = FingerprintTimingManager()

    static var debugOverlayEnabled = true

    struct TimeMappingEntry {
        let playbackTime: Double
        let referenceTime: Double
        let score: Float
    }

    private var currentEpisodeUUID: String?
    private var currentFilePath: String?
    private var currentMatcher: CheckpointMatcher?
    private var currentReference: ReferenceData?
    private var timeMapping: [TimeMappingEntry] = []        // sorted by playbackTime
    private var timeMappingByRef: [TimeMappingEntry] = []   // sorted by referenceTime
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.pocketcasts.fingerprint", qos: .userInitiated)
    private var isCancelled = false
    private var generationId: Int = 0
    private var lastKnownPlaybackPosition: Double = 0

    private(set) var isActive: Bool = false

    private init() {
        print("[FingerprintTiming] Singleton initialized")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onTrackChanged),
            name: Constants.Notifications.playbackTrackChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onTrackChanged),
            name: Constants.Notifications.playbackStarted,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPlaybackProgress),
            name: Constants.Notifications.playbackProgress,
            object: nil
        )
    }

    /// Call once at app launch to ensure the singleton is alive and listening for track changes.
    func setup() {
        if let episode = PlaybackManager.shared.currentEpisode() {
            onEpisodePlay(episode: episode)
        }
    }

    @objc private func onTrackChanged() {
        guard let episode = PlaybackManager.shared.currentEpisode() else {
            reset()
            return
        }
        onEpisodePlay(episode: episode)
    }

    @objc private func onPlaybackProgress() {
        let currentPos = PlaybackManager.shared.currentTime()
        let delta = abs(currentPos - lastKnownPlaybackPosition)
        lastKnownPlaybackPosition = currentPos

        guard currentEpisodeUUID != nil, currentFilePath != nil else { return }

        // Restart if playback jumped significantly
        if delta > 10 {
            restartFromCurrentPosition()
            return
        }

        // Also restart if playback is outside the fingerprinted range
        lock.lock()
        let mapping = timeMapping
        let active = isActive
        lock.unlock()

        if active, mapping.count >= 2,
           let first = mapping.first, let last = mapping.last {
            let margin = 30.0
            if currentPos < first.playbackTime - margin || currentPos > last.playbackTime + margin {
                restartFromCurrentPosition()
            }
        }
    }

    private func restartFromCurrentPosition() {
        lock.lock()
        guard let uuid = currentEpisodeUUID,
              let filePath = currentFilePath,
              let matcher = currentMatcher,
              let reference = currentReference else {
            lock.unlock()
            return
        }
        isCancelled = true
        generationId += 1
        let gen = generationId
        lock.unlock()

        queue.async { [weak self] in
            guard let self else { return }
            self.lock.lock()
            guard self.generationId == gen else {
                self.lock.unlock()
                return
            }
            self.isCancelled = false
            self.lock.unlock()

            self.processFile(uuid: uuid, audioFilePath: filePath, matcher: matcher, reference: reference)
        }
    }

    func onEpisodePlay(episode: BaseEpisode) {
        let uuid = episode.uuid

        if uuid == currentEpisodeUUID {
            return
        }

        reset()

        lock.lock()
        currentEpisodeUUID = uuid
        isCancelled = false
        generationId += 1
        lastKnownPlaybackPosition = PlaybackManager.shared.currentTime()
        lock.unlock()

        guard hasBundledFingerprint(for: uuid),
              let reference = loadReferenceCheckpoints(for: uuid) else {
            return
        }

        let isDownloaded = episode.downloaded(pathFinder: DownloadManager.shared)
        let filePath: String
        if isDownloaded {
            filePath = episode.pathToDownloadedFile(pathFinder: DownloadManager.shared)
        } else {
            filePath = DownloadManager.shared.streamingBufferPathForEpisode(episode)
        }

        let matcher = CheckpointMatcher.withDrift(maxDrift: 5)
        if reference.topK > 0 {
            matcher.setTopK(topK: UInt32(reference.topK))
        }
        for checkpoint in reference.checkpoints {
            matcher.add(
                timestamp: checkpoint.timestamp,
                hashes: checkpoint.hashes,
                duration: Float(reference.checkpointDuration)
            )
        }

        lock.lock()
        currentFilePath = filePath
        currentMatcher = matcher
        currentReference = reference
        lock.unlock()

        queue.async { [weak self] in
            self?.processFile(uuid: uuid, audioFilePath: filePath, matcher: matcher, reference: reference)
        }
    }

    func referenceTime(forPlaybackTime playbackTime: TimeInterval) -> TimeInterval? {
        lock.lock()
        let mapping = timeMapping
        let active = isActive
        lock.unlock()

        guard active, mapping.count >= 2 else { return nil }

        if playbackTime <= mapping.first!.playbackTime {
            return mapping.first!.referenceTime
        }
        if playbackTime >= mapping.last!.playbackTime {
            return mapping.last!.referenceTime
        }

        var low = 0
        var high = mapping.count - 1
        while low + 1 < high {
            let mid = (low + high) / 2
            if mapping[mid].playbackTime <= playbackTime {
                low = mid
            } else {
                high = mid
            }
        }

        let entry0 = mapping[low]
        let entry1 = mapping[high]
        let fraction = (playbackTime - entry0.playbackTime) / (entry1.playbackTime - entry0.playbackTime)
        return entry0.referenceTime + fraction * (entry1.referenceTime - entry0.referenceTime)
    }

    func playbackTime(forReferenceTime refTime: TimeInterval) -> TimeInterval? {
        lock.lock()
        let mapping = timeMappingByRef
        let active = isActive
        lock.unlock()

        guard active, mapping.count >= 2 else { return nil }

        if refTime <= mapping.first!.referenceTime {
            return mapping.first!.playbackTime
        }
        if refTime >= mapping.last!.referenceTime {
            return mapping.last!.playbackTime
        }

        var low = 0
        var high = mapping.count - 1
        while low + 1 < high {
            let mid = (low + high) / 2
            if mapping[mid].referenceTime <= refTime {
                low = mid
            } else {
                high = mid
            }
        }

        let entry0 = mapping[low]
        let entry1 = mapping[high]
        let span = entry1.referenceTime - entry0.referenceTime
        guard span > 0 else { return entry0.playbackTime }
        let fraction = (refTime - entry0.referenceTime) / span
        return entry0.playbackTime + fraction * (entry1.playbackTime - entry0.playbackTime)
    }

    /// Like `playbackTime(forReferenceTime:)` but triggers a background re-fingerprint
    /// if the target is outside the mapped range.
    func seekPlaybackTime(forReferenceTime refTime: TimeInterval) -> TimeInterval? {
        return playbackTime(forReferenceTime: refTime)
    }

    /// Returns a snapshot of the current mapping entries for the debug overlay.
    func debugMappingSnapshot() -> [TimeMappingEntry] {
        lock.lock()
        let snapshot = timeMapping
        lock.unlock()
        return snapshot
    }

    /// Total duration of the current episode's audio file in seconds, or nil if unknown.
    var totalDuration: Double? {
        lock.lock()
        let ref = currentReference
        lock.unlock()
        return ref?.totalDuration
    }

    func reset() {
        lock.lock()
        isCancelled = true
        generationId += 1
        currentEpisodeUUID = nil
        currentFilePath = nil
        currentMatcher = nil
        currentReference = nil

        timeMapping = []
        timeMappingByRef = []
        isActive = false
        lastKnownPlaybackPosition = 0
        lock.unlock()
    }

    // MARK: - File Fingerprinting

    private func processFile(uuid: String, audioFilePath: String, matcher: CheckpointMatcher, reference: ReferenceData) {
        print("[FingerprintTiming] Starting fingerprinting for \(uuid)")

        // Wait for the file to exist and have data (streaming buffer may not be ready yet)
        let fileURL = URL(fileURLWithPath: audioFilePath)
        var data: Data?
        for _ in 0..<60 {
            lock.lock()
            let cancelled = isCancelled
            lock.unlock()
            if cancelled { return }

            if let d = try? Data(contentsOf: fileURL), !d.isEmpty {
                data = d
                break
            }
            Thread.sleep(forTimeInterval: 1.0)
        }

        guard let data else {
            print("[FingerprintTiming] Failed to read file after waiting")
            return
        }

        guard let windows = fingerprintData(data, reference: reference) else { return }

        // Process in batches so the debug overlay fills progressively
        let batchSize = 50
        for batchStart in stride(from: 0, to: windows.count, by: batchSize) {
            lock.lock()
            let cancelled = isCancelled
            lock.unlock()
            if cancelled { return }

            let batchEnd = min(batchStart + batchSize, windows.count)
            let batch = Array(windows[batchStart..<batchEnd])
            processWindows(batch, matcher: matcher, uuid: uuid)
        }

        lock.lock()
        let count = timeMapping.count
        lock.unlock()
        print("[FingerprintTiming] Done: \(count) mapping points for \(uuid)")
    }

    /// Fingerprint raw file data and return the windows, or nil on failure.
    private func fingerprintData(_ data: Data, reference: ReferenceData) -> [WindowedFingerprint]? {
        let fingerprinter = Fingerprinter()
        do {
            return try fingerprinter.fingerprintDataWindowed(
                data: data,
                windowDurationMs: UInt32(reference.checkpointDuration * 1000),
                windowIntervalMs: UInt32(reference.checkpointInterval * 1000)
            )
        } catch {
            print("[FingerprintTiming] Fingerprinting failed: \(error)")
            return nil
        }
    }

    // MARK: - Private

    private func hasBundledFingerprint(for uuid: String) -> Bool {
        Bundle.main.url(forResource: uuid, withExtension: "json") != nil
    }

    private func processWindows(_ windows: [WindowedFingerprint], matcher: CheckpointMatcher, uuid: String) {
        guard !windows.isEmpty else { return }

        var newEntries: [TimeMappingEntry] = []
        for window in windows {
            let matches = matcher.findTopMatches(queryHashes: window.hashes, maxResults: 1)
            guard let best = matches.first, best.score > 0.5 else { continue }
            newEntries.append(TimeMappingEntry(
                playbackTime: Double(window.timestampMs) / 1000.0,
                referenceTime: Double(best.timestamp),
                score: best.score
            ))
        }

        guard !newEntries.isEmpty else { return }

        lock.lock()
        guard currentEpisodeUUID == uuid, !isCancelled else {
            lock.unlock()
            return
        }
        timeMapping.append(contentsOf: newEntries)
        timeMapping.sort { $0.playbackTime < $1.playbackTime }
        timeMappingByRef.append(contentsOf: newEntries)
        timeMappingByRef.sort { $0.referenceTime < $1.referenceTime }
        if timeMapping.count >= 2 && !isActive {
            isActive = true
            print("[FingerprintTiming] Active with \(timeMapping.count) mapping points")
        }
        lock.unlock()
    }

    // MARK: - JSON Parsing

    private struct ReferenceData {
        let checkpointInterval: Int
        let checkpointDuration: Int
        let totalDuration: Double
        let topK: Int
        let checkpoints: [(timestamp: Float, hashes: [UInt32])]
    }

    private func loadReferenceCheckpoints(for uuid: String) -> ReferenceData? {
        guard let url = Bundle.main.url(forResource: uuid, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let checkpointInterval = json["checkpoint_interval"] as? Int,
              let checkpointDuration = json["checkpoint_duration"] as? Int else {
            return nil
        }

        let totalDuration = json["total_duration"] as? Double ?? 0
        let timestampQuantum = json["timestamp_quantum"] as? Int ?? 1
        let topK = json["top_k"] as? Int ?? 0
        let format = json["format"] as? String ?? ""

        var checkpoints: [(timestamp: Float, hashes: [UInt32])] = []

        if format == "fingerprint-compact-v2",
           let checkpointArray = json["checkpoints"] as? [[Any]] {
            var tsUnit: Int = 0
            for entry in checkpointArray {
                guard entry.count == 2,
                      let delta = entry[0] as? Int,
                      let encoded = entry[1] as? String else { continue }
                tsUnit += delta
                let timestamp = Float(tsUnit * timestampQuantum)
                guard let hashes = unpackBase64Hashes(encoded), !hashes.isEmpty else { continue }
                checkpoints.append((timestamp: timestamp, hashes: hashes))
            }
        } else if let checkpointsDict = json["checkpoints"] as? [String: String] {
            for (key, value) in checkpointsDict {
                guard let timestamp = Float(key) else { continue }
                let hashes = value.split(separator: ",").compactMap { UInt32($0) }
                guard !hashes.isEmpty else { continue }
                checkpoints.append((timestamp: timestamp, hashes: hashes))
            }
            checkpoints.sort { $0.timestamp < $1.timestamp }
        }

        print("[FingerprintTiming] Loaded reference: format=\(format), checkpoints=\(checkpoints.count), interval=\(checkpointInterval)s, duration=\(checkpointDuration)s, topK=\(topK)")

        return ReferenceData(
            checkpointInterval: checkpointInterval,
            checkpointDuration: checkpointDuration,
            totalDuration: totalDuration,
            topK: topK,
            checkpoints: checkpoints
        )
    }

    /// Decode base64 (no padding) -> little-endian u32 array
    private func unpackBase64Hashes(_ encoded: String) -> [UInt32]? {
        guard let data = Data(base64Encoded: padBase64(encoded)) else { return nil }
        guard data.count % 4 == 0 else { return nil }
        var hashes: [UInt32] = []
        hashes.reserveCapacity(data.count / 4)
        for i in stride(from: 0, to: data.count, by: 4) {
            let value = UInt32(data[i])
                | (UInt32(data[i + 1]) << 8)
                | (UInt32(data[i + 2]) << 16)
                | (UInt32(data[i + 3]) << 24)
            hashes.append(value)
        }
        return hashes
    }

    /// Add base64 padding if missing (the Rust encoder uses no-pad)
    private func padBase64(_ str: String) -> String {
        let remainder = str.count % 4
        if remainder == 0 { return str }
        return str + String(repeating: "=", count: 4 - remainder)
    }
}
