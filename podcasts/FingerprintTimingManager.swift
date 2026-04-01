import Foundation
import Fingerprint
import PocketCastsDataModel

class FingerprintTimingManager {
    static let shared = FingerprintTimingManager()

    private struct TimeMappingEntry {
        let playbackTime: Double
        let referenceTime: Double
    }

    private var currentEpisodeUUID: String?
    private var timeMapping: [TimeMappingEntry] = []
    private var isProcessing = false
    private let queue = DispatchQueue(label: "com.pocketcasts.fingerprint", qos: .userInitiated)

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
        // Also check if an episode is already playing
        if let episode = PlaybackManager.shared.currentEpisode() {
            onEpisodePlay(episode: episode)
        }
    }

    @objc private func onTrackChanged() {
        print("[FingerprintTiming] onTrackChanged notification received")
        guard let episode = PlaybackManager.shared.currentEpisode() else {
            print("[FingerprintTiming] No current episode")
            reset()
            return
        }
        onEpisodePlay(episode: episode)
    }

    func onEpisodePlay(episode: BaseEpisode) {
        let uuid = episode.uuid
        print("[FingerprintTiming] onEpisodePlay called for uuid: \(uuid)")

        if uuid == currentEpisodeUUID, isActive || isProcessing {
            print("[FingerprintTiming] Already active/processing for this episode, skipping")
            return
        }

        reset()
        currentEpisodeUUID = uuid

        let hasFingerprint = hasBundledFingerprint(for: uuid)
        let isDownloaded = episode.downloaded(pathFinder: DownloadManager.shared)
        print("[FingerprintTiming] hasBundledFingerprint: \(hasFingerprint), isDownloaded: \(isDownloaded)")

        guard hasFingerprint, isDownloaded else {
            return
        }

        isProcessing = true
        let filePath = episode.pathToDownloadedFile(pathFinder: DownloadManager.shared)
        print("[FingerprintTiming] Starting fingerprinting, audioFile: \(filePath)")

        queue.async { [weak self] in
            self?.processFingerprinting(uuid: uuid, audioFilePath: filePath)
        }
    }

    func referenceTime(forPlaybackTime playbackTime: TimeInterval) -> TimeInterval? {
        guard isActive, timeMapping.count >= 2 else { return nil }

        let mapping = timeMapping

        if playbackTime <= mapping.first!.playbackTime {
            return mapping.first!.referenceTime
        }
        if playbackTime >= mapping.last!.playbackTime {
            return mapping.last!.referenceTime
        }

        // Binary search for bracketing entries
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
        guard isActive, timeMapping.count >= 2 else { return nil }

        let mapping = timeMapping

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

    func reset() {
        currentEpisodeUUID = nil
        timeMapping = []
        isProcessing = false
        isActive = false
    }

    // MARK: - Private

    private func hasBundledFingerprint(for uuid: String) -> Bool {
        Bundle.main.url(forResource: uuid, withExtension: "json") != nil
    }

    private func processFingerprinting(uuid: String, audioFilePath: String) {
        guard let referenceCheckpoints = loadReferenceCheckpoints(for: uuid) else {
            DispatchQueue.main.async { self.isProcessing = false }
            return
        }

        guard let audioData = FileManager.default.contents(atPath: audioFilePath) else {
            DispatchQueue.main.async { self.isProcessing = false }
            return
        }

        let matcher = CheckpointMatcher.withDrift(maxDrift: 5)
        for checkpoint in referenceCheckpoints.checkpoints {
            matcher.add(
                timestamp: checkpoint.timestamp,
                hashes: checkpoint.hashes,
                duration: Float(referenceCheckpoints.checkpointDuration)
            )
        }

        let fingerprinter = Fingerprinter()
        let windows: [WindowedFingerprint]
        do {
            windows = try fingerprinter.fingerprintDataWindowed(
                data: audioData,
                windowDurationMs: UInt32(referenceCheckpoints.checkpointDuration * 1000),
                windowIntervalMs: UInt32(referenceCheckpoints.checkpointInterval * 1000)
            )
        } catch {
            print("[FingerprintTiming] Failed to fingerprint audio: \(error)")
            DispatchQueue.main.async { self.isProcessing = false }
            return
        }

        var mapping: [TimeMappingEntry] = []
        for window in windows {
            let matches = matcher.findTopMatches(queryHashes: window.hashes, maxResults: 1)
            guard let best = matches.first, best.score > 0.5 else { continue }
            mapping.append(TimeMappingEntry(
                playbackTime: Double(window.timestampMs) / 1000.0,
                referenceTime: Double(best.timestamp)
            ))
        }

        mapping.sort { $0.playbackTime < $1.playbackTime }

        DispatchQueue.main.async {
            guard self.currentEpisodeUUID == uuid else { return }
            self.timeMapping = mapping
            self.isActive = mapping.count >= 2
            self.isProcessing = false
            print("[FingerprintTiming] Ready with \(mapping.count) mapping points for \(uuid)")
        }
    }

    // MARK: - JSON Parsing

    private struct ReferenceData {
        let checkpointInterval: Int
        let checkpointDuration: Int
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
            checkpoints: checkpoints
        )
    }
}
