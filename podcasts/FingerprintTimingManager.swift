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
    private var currentIsStreaming: Bool = false
    private var timeMapping: [TimeMappingEntry] = []        // sorted by playbackTime
    private var timeMappingByRef: [TimeMappingEntry] = []  // sorted by referenceTime
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.pocketcasts.fingerprint", qos: .userInitiated)
    private var isCancelled = false
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
        lastKnownPlaybackPosition = PlaybackManager.shared.currentTime()
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

        lastKnownPlaybackPosition = PlaybackManager.shared.currentTime()
        lock.unlock()

        guard hasBundledFingerprint(for: uuid),
              let reference = loadReferenceCheckpoints(for: uuid) else {
            return
        }

        let isDownloaded = episode.downloaded(pathFinder: DownloadManager.shared)
        let isBuffered = episode.bufferedForStreaming()
        let filePath: String
        if isDownloaded {
            filePath = episode.pathToDownloadedFile(pathFinder: DownloadManager.shared)
        } else {
            filePath = DownloadManager.shared.streamingBufferPathForEpisode(episode)
        }
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: filePath)[.size] as? UInt64) ?? 0
        print("[FingerprintTiming] Episode status: downloaded=\(isDownloaded), buffered=\(isBuffered), path=\(filePath), fileSize=\(fileSize)")

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
        currentIsStreaming = !isDownloaded
        lock.unlock()

        let streaming = !isDownloaded
        queue.async { [weak self] in
            self?.processFileProgressively(uuid: uuid, audioFilePath: filePath, matcher: matcher, reference: reference, isStreaming: streaming)
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

        currentEpisodeUUID = nil
        currentFilePath = nil
        currentMatcher = nil
        currentReference = nil
        currentIsStreaming = false
        timeMapping = []
        timeMappingByRef = []
        isActive = false
        lastKnownPlaybackPosition = 0
        lock.unlock()
    }

    // MARK: - Batch File Fingerprinting

    private func processFileProgressively(uuid: String, audioFilePath: String, matcher: CheckpointMatcher, reference: ReferenceData, isStreaming: Bool = false) {
        print("[FingerprintTiming] Starting batch fingerprinting for \(uuid), streaming=\(isStreaming)")

        if isStreaming {
            // For streaming: poll for file data and fingerprint as it grows
            fingerprintStreamingFile(path: audioFilePath, reference: reference, matcher: matcher, uuid: uuid)
        } else {
            // For downloaded: read the whole file and fingerprint it
            fingerprintLocalFile(path: audioFilePath, reference: reference, matcher: matcher, uuid: uuid)
        }

        lock.lock()
        let count = timeMapping.count
        lock.unlock()
        print("[FingerprintTiming] Done: \(count) mapping points for \(uuid)")
    }

    private func fingerprintLocalFile(path: String, reference: ReferenceData, matcher: CheckpointMatcher, uuid: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("[FingerprintTiming] Failed to read file")
            return
        }
        var knownTimestamps: Set<UInt32> = []
        fingerprintData(data, reference: reference, matcher: matcher, uuid: uuid, knownTimestamps: &knownTimestamps)
    }

    private func fingerprintStreamingFile(path: String, reference: ReferenceData, matcher: CheckpointMatcher, uuid: String) {
        var lastProcessedSize: UInt64 = 0
        var stallCount = 0
        var knownTimestamps: Set<UInt32> = []

        while stallCount < 120 {
            lock.lock()
            let cancelled = isCancelled
            lock.unlock()
            if cancelled { return }

            let fileURL = URL(fileURLWithPath: path)
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                  let fileSize = attrs[.size] as? UInt64,
                  fileSize > 0 else {
                stallCount += 1
                Thread.sleep(forTimeInterval: 0.5)
                continue
            }

            if fileSize > lastProcessedSize {
                stallCount = 0
                lastProcessedSize = fileSize

                if let data = try? Data(contentsOf: fileURL) {
                    // Fingerprint the whole buffer, but only add new windows
                    fingerprintData(data, reference: reference, matcher: matcher, uuid: uuid, knownTimestamps: &knownTimestamps)
                }
            } else {
                stallCount += 1
            }

            Thread.sleep(forTimeInterval: 2.0)
        }
    }

    private func fingerprintData(_ data: Data, reference: ReferenceData, matcher: CheckpointMatcher, uuid: String, knownTimestamps: inout Set<UInt32>) {
        print("[FingerprintTiming] File size: \(data.count) bytes, window=\(reference.checkpointDuration)s, interval=\(reference.checkpointInterval)s")
        print("[FingerprintTiming] File header bytes: \(Array(data.prefix(16)).map { String(format: "%02x", $0) }.joined(separator: " "))")

        // Dump first few reference checkpoint hashes
        for i in 0..<min(3, reference.checkpoints.count) {
            let cp = reference.checkpoints[i]
            let hashStrings = cp.hashes.prefix(10).map { String(format: "0x%08X", $0) }.joined(separator: ", ")
            print("[FingerprintTiming] REF[\(i)] ts=\(cp.timestamp) hashes(\(cp.hashes.count)): [\(hashStrings)]")
        }

        let fingerprinter = Fingerprinter()
        let windows: [WindowedFingerprint]
        do {
            windows = try fingerprinter.fingerprintDataWindowed(
                data: data,
                windowDurationMs: UInt32(reference.checkpointDuration * 1000),
                windowIntervalMs: UInt32(reference.checkpointInterval * 1000)
            )
        } catch {
            print("[FingerprintTiming] Fingerprinting failed: \(error)")
            return
        }

        print("[FingerprintTiming] Generated \(windows.count) windows")

        // Export fingerprint to file for debugging
        if knownTimestamps.isEmpty {
            exportFingerprint(windows: windows, reference: reference, uuid: uuid, fileSize: data.count)
        }

        // Dump first few query window hashes
        for i in 0..<min(3, windows.count) {
            let w = windows[i]
            let hashStrings = w.hashes.prefix(10).map { String(format: "0x%08X", $0) }.joined(separator: ", ")
            print("[FingerprintTiming] QUERY[\(i)] ts=\(w.timestampMs)ms dur=\(w.durationMs)ms hashes(\(w.hashes.count)): [\(hashStrings)]")
        }

        // Direct compare first few windows against first few checkpoints
        for qi in 0..<min(3, windows.count) {
            for ri in 0..<min(3, reference.checkpoints.count) {
                let score = compareHashesWithDrift(hashes1: Array(windows[qi].hashes), hashes2: Array(reference.checkpoints[ri].hashes), maxDrift: 5)
                print("[FingerprintTiming] Compare query[\(qi)] vs ref[\(ri)]: score=\(String(format: "%.4f", score))")
            }
        }
        // Only process windows we haven't seen before
        let newWindows = windows.filter { !knownTimestamps.contains($0.timestampMs) }
        for window in newWindows {
            knownTimestamps.insert(window.timestampMs)
        }
        processWindows(newWindows, matcher: matcher, uuid: uuid)
    }

    // MARK: - Private

    private func hasBundledFingerprint(for uuid: String) -> Bool {
        Bundle.main.url(forResource: uuid, withExtension: "json") != nil
    }

    private func processWindows(_ windows: [WindowedFingerprint], matcher: CheckpointMatcher, uuid: String) {
        guard !windows.isEmpty else { return }

        var newEntries: [TimeMappingEntry] = []
        var scoreDistribution: [String: Int] = ["<0.5": 0, "0.5-0.7": 0, "0.7-0.85": 0, "0.85+": 0]
        var refTimestampCounts: [Float: Int] = [:]

        for (i, window) in windows.enumerated() {
            // Get top 3 to see if there's a dominant checkpoint
            let matches = matcher.findTopMatches(queryHashes: window.hashes, maxResults: 3)
            if i < 10, !matches.isEmpty {
                let matchDesc = matches.prefix(3).map { "ref@\($0.timestamp)s=\(String(format: "%.3f", $0.score))" }.joined(separator: ", ")
                print("[FingerprintTiming] Window @\(window.timestampMs)ms (\(window.hashes.count)h) -> [\(matchDesc)]")
            }
            guard let best = matches.first else { continue }

            // Track score distribution
            if best.score < 0.5 { scoreDistribution["<0.5"]! += 1 }
            else if best.score < 0.7 { scoreDistribution["0.5-0.7"]! += 1 }
            else if best.score < 0.85 { scoreDistribution["0.7-0.85"]! += 1 }
            else { scoreDistribution["0.85+"]! += 1 }

            guard best.score > 0.5 else { continue }

            refTimestampCounts[best.timestamp, default: 0] += 1
            newEntries.append(TimeMappingEntry(
                playbackTime: Double(window.timestampMs) / 1000.0,
                referenceTime: Double(best.timestamp),
                score: best.score
            ))
        }

        print("[FingerprintTiming] Score distribution: \(scoreDistribution)")
        if !refTimestampCounts.isEmpty {
            let sorted = refTimestampCounts.sorted { $0.value > $1.value }
            let topRefs = sorted.prefix(5).map { "ref@\($0.key)s=\($0.value)x" }.joined(separator: ", ")
            print("[FingerprintTiming] Top matched ref timestamps: \(topRefs) (unique=\(refTimestampCounts.count))")
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
        }
        let count = timeMapping.count
        let refFirst = timeMappingByRef.first!
        let refLast = timeMappingByRef.last!
        print("[FingerprintTiming] Mapping: \(count) entries, ref=[\(String(format: "%.1f", refFirst.referenceTime))..\(String(format: "%.1f", refLast.referenceTime))] playback=[\(String(format: "%.1f", timeMapping.first!.playbackTime))..\(String(format: "%.1f", timeMapping.last!.playbackTime))]")
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
            // compact-v2: delta-encoded timestamps + base64-packed LE u32 hashes
            var tsUnit: Int = 0
            var decodeFailCount = 0
            for (i, entry) in checkpointArray.enumerated() {
                guard entry.count == 2,
                      let delta = entry[0] as? Int,
                      let encoded = entry[1] as? String else { continue }
                tsUnit += delta
                let timestamp = Float(tsUnit * timestampQuantum)
                guard let hashes = unpackBase64Hashes(encoded), !hashes.isEmpty else {
                    decodeFailCount += 1
                    if decodeFailCount <= 3 {
                        print("[FingerprintTiming] DECODE FAIL checkpoint[\(i)] base64 len=\(encoded.count) first40='\(String(encoded.prefix(40)))'")
                    }
                    continue
                }
                if i < 3 {
                    let hashStrings = hashes.prefix(5).map { String(format: "0x%08X", $0) }.joined(separator: ", ")
                    print("[FingerprintTiming] Parsed ref[\(i)] ts=\(timestamp) base64Len=\(encoded.count) hashCount=\(hashes.count) first5=[\(hashStrings)]")
                }
                checkpoints.append((timestamp: timestamp, hashes: hashes))
            }
            if decodeFailCount > 0 {
                print("[FingerprintTiming] WARNING: \(decodeFailCount)/\(checkpointArray.count) checkpoints failed to decode")
            }
        } else if let checkpointsDict = json["checkpoints"] as? [String: String] {
            // Legacy format: string timestamp keys -> comma-separated hashes
            for (key, value) in checkpointsDict {
                guard let timestamp = Float(key) else { continue }
                let hashes = value.split(separator: ",").compactMap { UInt32($0) }
                guard !hashes.isEmpty else { continue }
                checkpoints.append((timestamp: timestamp, hashes: hashes))
            }
            checkpoints.sort { $0.timestamp < $1.timestamp }
        }

        print("[FingerprintTiming] Loaded reference: format=\(format), checkpoints=\(checkpoints.count), interval=\(checkpointInterval)s, duration=\(checkpointDuration)s, topK=\(topK), quantum=\(timestampQuantum)")

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

    private func exportFingerprint(windows: [WindowedFingerprint], reference: ReferenceData, uuid: String, fileSize: Int) {
        var checkpoints: [[Any]] = []
        var prevTs: Int = 0
        for window in windows {
            let ts = Int(window.timestampMs) / 1000
            let delta = ts - prevTs
            prevTs = ts
            checkpoints.append([delta, window.hashes.map { $0 }])
        }

        let payload: [String: Any] = [
            "format": "fingerprint-debug-v1",
            "source": "ios-app",
            "episode_uuid": uuid,
            "source_file_size": fileSize,
            "checkpoint_duration": reference.checkpointDuration,
            "checkpoint_interval": reference.checkpointInterval,
            "total_windows": windows.count,
            "hashes_per_window": windows.first?.hashes.count ?? 0,
            "checkpoints": checkpoints
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("[FingerprintTiming] Failed to serialize export")
            return
        }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportURL = docs.appendingPathComponent("\(uuid)-ios-fingerprint.json")
        do {
            try jsonData.write(to: exportURL)
            print("[FingerprintTiming] Exported fingerprint to: \(exportURL.path)")
        } catch {
            print("[FingerprintTiming] Export failed: \(error)")
        }
    }

    /// Add base64 padding if missing (the Rust encoder uses no-pad)
    private func padBase64(_ str: String) -> String {
        let remainder = str.count % 4
        if remainder == 0 { return str }
        return str + String(repeating: "=", count: 4 - remainder)
    }

}
