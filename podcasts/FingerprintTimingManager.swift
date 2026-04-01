import AVFoundation
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
    private var timeMapping: [TimeMappingEntry] = []
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.pocketcasts.fingerprint", qos: .userInitiated)
    private var isCancelled = false

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

    func onEpisodePlay(episode: BaseEpisode) {
        let uuid = episode.uuid

        if uuid == currentEpisodeUUID {
            return
        }

        reset()

        lock.lock()
        currentEpisodeUUID = uuid
        isCancelled = false
        lock.unlock()

        guard hasBundledFingerprint(for: uuid),
              episode.downloaded(pathFinder: DownloadManager.shared),
              let reference = loadReferenceCheckpoints(for: uuid) else {
            return
        }

        let filePath = episode.pathToDownloadedFile(pathFinder: DownloadManager.shared)

        let matcher = CheckpointMatcher.withDrift(maxDrift: 5)
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
            self?.processFileProgressively(uuid: uuid, audioFilePath: filePath, matcher: matcher, reference: reference)
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
        let mapping = timeMapping
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

    /// Like `playbackTime(forReferenceTime:)` but if the target is outside the mapped range,
    /// performs a targeted fingerprint of that region to get an accurate result.
    func seekPlaybackTime(forReferenceTime refTime: TimeInterval) -> TimeInterval? {
        // Try existing mapping first
        if let result = playbackTime(forReferenceTime: refTime) {
            lock.lock()
            let mapping = timeMapping
            lock.unlock()
            // Only trust if refTime is within the mapped range
            if let first = mapping.first, let last = mapping.last,
               refTime >= first.referenceTime, refTime <= last.referenceTime {
                return result
            }
        }

        // Need to jump-ahead fingerprint
        lock.lock()
        let filePath = currentFilePath
        let matcher = currentMatcher
        let reference = currentReference
        let uuid = currentEpisodeUUID
        let mapping = timeMapping
        lock.unlock()

        guard let filePath, let matcher, let reference, let uuid else { return nil }

        // Estimate the file position: extrapolate from last mapping point if available,
        // otherwise use refTime directly as approximate seconds offset
        let estimatedPlaybackTime: Double
        if let last = mapping.last, last.referenceTime > 0 {
            let offset = last.playbackTime - last.referenceTime
            estimatedPlaybackTime = refTime + offset
        } else {
            estimatedPlaybackTime = refTime
        }

        let fileURL = URL(fileURLWithPath: filePath)
        guard let audioFile = try? AVAudioFile(
            forReading: fileURL,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        ) else { return nil }

        let sampleRate = audioFile.fileFormat.sampleRate
        let channels = UInt16(audioFile.processingFormat.channelCount)
        let seekSeconds = max(0, estimatedPlaybackTime - 5)
        let seekFrame = AVAudioFramePosition(seekSeconds * sampleRate)
        audioFile.framePosition = min(seekFrame, audioFile.length)

        let fingerprinter = StreamingWindowedFingerprinter(
            sampleRate: UInt32(sampleRate),
            channels: channels,
            windowDurationMs: UInt32(reference.checkpointDuration * 1000),
            windowIntervalMs: UInt32(reference.checkpointInterval * 1000)
        )

        // Read ~15 seconds of audio
        let framesToRead = AVAudioFrameCount(15.0 * sampleRate)
        let bufferSize: AVAudioFrameCount = 8192
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: bufferSize) else {
            return nil
        }

        var framesRead: AVAudioFrameCount = 0
        while framesRead < framesToRead, audioFile.framePosition < audioFile.length {
            do {
                try audioFile.read(into: buffer)
            } catch {
                break
            }
            guard buffer.frameLength > 0, let channelData = buffer.floatChannelData else { break }

            let frames = Int(buffer.frameLength)
            let chCount = Int(channels)
            var interleaved = [Float](repeating: 0, count: frames * chCount)
            for frame in 0..<frames {
                for ch in 0..<chCount {
                    interleaved[frame * chCount + ch] = channelData[ch][frame]
                }
            }
            let windows = fingerprinter.pushSamplesF32(samples: interleaved, channels: channels)

            // Offset timestamps: the fingerprinter counts from 0 but we started at seekSeconds
            var newEntries: [TimeMappingEntry] = []
            for window in windows {
                let matches = matcher.findTopMatches(queryHashes: window.hashes, maxResults: 1)
                guard let best = matches.first, best.score > 0.5 else { continue }
                newEntries.append(TimeMappingEntry(
                    playbackTime: seekSeconds + Double(window.timestampMs) / 1000.0,
                    referenceTime: Double(best.timestamp),
                    score: best.score
                ))
            }
            if !newEntries.isEmpty {
                lock.lock()
                guard currentEpisodeUUID == uuid else {
                    lock.unlock()
                    return nil
                }
                timeMapping.append(contentsOf: newEntries)
                timeMapping.sort { $0.playbackTime < $1.playbackTime }
                if timeMapping.count >= 2 { isActive = true }
                lock.unlock()
            }

            framesRead += buffer.frameLength
        }

        // Flush
        let finalWindows = fingerprinter.flush()
        var finalEntries: [TimeMappingEntry] = []
        for window in finalWindows {
            let matches = matcher.findTopMatches(queryHashes: window.hashes, maxResults: 1)
            guard let best = matches.first, best.score > 0.5 else { continue }
            finalEntries.append(TimeMappingEntry(
                playbackTime: seekSeconds + Double(window.timestampMs) / 1000.0,
                referenceTime: Double(best.timestamp),
                score: best.score
            ))
        }
        if !finalEntries.isEmpty {
            lock.lock()
            guard currentEpisodeUUID == uuid else {
                lock.unlock()
                return nil
            }
            timeMapping.append(contentsOf: finalEntries)
            timeMapping.sort { $0.playbackTime < $1.playbackTime }
            if timeMapping.count >= 2 { isActive = true }
            lock.unlock()
        }

        // Now try the lookup again with the new mapping points
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
        timeMapping = []
        isActive = false
        lock.unlock()
    }

    // MARK: - Progressive File Reading

    private func processFileProgressively(uuid: String, audioFilePath: String, matcher: CheckpointMatcher, reference: ReferenceData) {
        let playbackPos = PlaybackManager.shared.currentTime()
        let interval = Double(reference.checkpointInterval)
        // Start one window-duration before playback, snapped to the checkpoint interval grid
        let warmupStart = max(0, floor((playbackPos - Double(reference.checkpointDuration)) / interval) * interval)

        print("[FingerprintTiming] Starting progressive fingerprinting for \(uuid), playback=\(playbackPos)s, warmup=\(warmupStart)s")

        let fileURL = URL(fileURLWithPath: audioFilePath)

        // Pass 1: from warmup position forward to EOF
        fingerprintFileRange(
            fileURL: fileURL, from: warmupStart, to: .infinity,
            reference: reference, matcher: matcher, uuid: uuid
        )

        // Pass 2: fill in from 0 up to where we started
        if warmupStart > 0 {
            fingerprintFileRange(
                fileURL: fileURL, from: 0, to: warmupStart + Double(reference.checkpointDuration),
                reference: reference, matcher: matcher, uuid: uuid
            )
        }

        lock.lock()
        let count = timeMapping.count
        lock.unlock()
        print("[FingerprintTiming] Done: \(count) mapping points for \(uuid)")
    }

    private func fingerprintFileRange(
        fileURL: URL, from startSeconds: Double, to endSeconds: Double,
        reference: ReferenceData, matcher: CheckpointMatcher, uuid: String
    ) {
        guard let audioFile = try? AVAudioFile(
            forReading: fileURL,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        ) else { return }

        let sampleRate = audioFile.fileFormat.sampleRate
        let channels = UInt16(audioFile.processingFormat.channelCount)

        let startFrame = AVAudioFramePosition(startSeconds * sampleRate)
        audioFile.framePosition = min(startFrame, audioFile.length)

        let endFrame: AVAudioFramePosition
        if endSeconds == .infinity {
            endFrame = audioFile.length
        } else {
            endFrame = min(AVAudioFramePosition(endSeconds * sampleRate), audioFile.length)
        }

        let fingerprinter = StreamingWindowedFingerprinter(
            sampleRate: UInt32(sampleRate),
            channels: channels,
            windowDurationMs: UInt32(reference.checkpointDuration * 1000),
            windowIntervalMs: UInt32(reference.checkpointInterval * 1000)
        )

        let bufferSize: AVAudioFrameCount = 8192
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: bufferSize) else {
            return
        }

        while audioFile.framePosition < endFrame {
            lock.lock()
            let cancelled = isCancelled
            lock.unlock()
            if cancelled { return }

            do {
                try audioFile.read(into: buffer)
            } catch {
                break
            }

            guard buffer.frameLength > 0, let channelData = buffer.floatChannelData else { break }

            let frames = Int(buffer.frameLength)
            let chCount = Int(channels)
            var interleaved = [Float](repeating: 0, count: frames * chCount)
            for frame in 0..<frames {
                for ch in 0..<chCount {
                    interleaved[frame * chCount + ch] = channelData[ch][frame]
                }
            }

            let windows = fingerprinter.pushSamplesF32(samples: interleaved, channels: channels)

            // Offset timestamps by the start position of this range
            let offsetWindows = windows.map { window in
                WindowedFingerprint(
                    timestampMs: window.timestampMs + UInt32(startSeconds * 1000),
                    durationMs: window.durationMs,
                    hashes: window.hashes
                )
            }
            processWindows(offsetWindows, matcher: matcher, uuid: uuid)
        }

        let finalWindows = fingerprinter.flush()
        let offsetFinal = finalWindows.map { window in
            WindowedFingerprint(
                timestampMs: window.timestampMs + UInt32(startSeconds * 1000),
                durationMs: window.durationMs,
                hashes: window.hashes
            )
        }
        processWindows(offsetFinal, matcher: matcher, uuid: uuid)
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
        let checkpoints: [(timestamp: Float, hashes: [UInt32])]
    }

    private func loadReferenceCheckpoints(for uuid: String) -> ReferenceData? {
        guard let url = Bundle.main.url(forResource: uuid, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let checkpointInterval = json["checkpoint_interval"] as? Int,
              let checkpointDuration = json["checkpoint_duration"] as? Int,
              let checkpointsDict = json["checkpoints"] as? [String: String] else {
            return nil
        }

        let totalDuration = json["total_duration"] as? Double ?? 0

        var checkpoints: [(timestamp: Float, hashes: [UInt32])] = []
        for (key, value) in checkpointsDict {
            guard let timestamp = Float(key) else { continue }
            let hashes = value.split(separator: ",").compactMap { UInt32($0) }
            guard !hashes.isEmpty else { continue }
            checkpoints.append((timestamp: timestamp, hashes: hashes))
        }

        checkpoints.sort { $0.timestamp < $1.timestamp }

        return ReferenceData(
            checkpointInterval: checkpointInterval,
            checkpointDuration: checkpointDuration,
            totalDuration: totalDuration,
            checkpoints: checkpoints
        )
    }
}
