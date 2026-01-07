import Foundation
import PocketCastsUtils
import PocketCastsDataModel
#if os(iOS)
import Fingerprint
#endif

/// Service for managing audio fingerprints - fetching reference fingerprints from server
/// and generating client fingerprints from downloaded audio files.
public actor FingerprintService {
    public static let shared = FingerprintService()

    /// Base URL for fetching fingerprints from the server.
    private static let fingerprintBaseURL = "https://shownotes.pocketcasts.net/fingerprints"

    /// In-memory cache for reference fingerprints (keyed by episode UUID).
    private var referenceCache: [String: FingerprintFileData] = [:]

    /// In-memory cache for client fingerprints (keyed by episode UUID).
    private var clientCache: [String: [String: String]] = [:]

    /// Tracks in-flight fetch requests to avoid duplicate network calls.
    private var fetchTasks: [String: Task<FingerprintFileData?, Error>] = [:]

    /// Tracks in-flight generation tasks to avoid duplicate processing.
    private var generationTasks: [String: Task<[String: String]?, Never>] = [:]

    /// URL cache for HTTP responses.
    private let urlCache: URLCache

    #if os(iOS)
    /// Fingerprinter instance for generating client fingerprints.
    private lazy var fingerprinter = Fingerprinter()
    #endif

    /// Disk cache directory for persisted fingerprints.
    private let diskCacheDirectory: URL

    private init() {
        urlCache = URLCache(
            memoryCapacity: 5.megabytes,
            diskCapacity: 50.megabytes,
            diskPath: "fingerprints"
        )

        // Set up disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cacheDir.appendingPathComponent("fingerprints", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Reference Fingerprints

    /// Fetch reference fingerprints from the server for an episode.
    ///
    /// - Parameters:
    ///   - podcastUuid: The podcast UUID.
    ///   - episodeUuid: The episode UUID.
    /// - Returns: The fingerprint data, or nil if not available.
    public func fetchReferenceFingerprints(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> FingerprintFileData? {
        // Check memory cache first
        if let cached = referenceCache[episodeUuid] {
            FileLog.shared.addMessage("FingerprintService: returning cached reference fingerprints for \(episodeUuid)")
            return cached
        }

        // Check disk cache
        if let diskCached = loadFromDiskCache(episodeUuid: episodeUuid, isClient: false) {
            referenceCache[episodeUuid] = diskCached
            FileLog.shared.addMessage("FingerprintService: loaded reference fingerprints from disk for \(episodeUuid)")
            return diskCached
        }

        // Check for in-flight request
        if let existingTask = fetchTasks[episodeUuid] {
            return try await existingTask.value
        }

        // Create new fetch task
        let task = Task<FingerprintFileData?, Error> {
            defer { fetchTasks[episodeUuid] = nil }

            let urlString = "\(Self.fingerprintBaseURL)/\(podcastUuid)/\(episodeUuid).json"
            guard let url = URL(string: urlString) else {
                FileLog.shared.addMessage("FingerprintService: invalid URL for fingerprints: \(urlString)")
                return nil
            }

            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)

            // Check URL cache
            if let cachedResponse = urlCache.cachedResponse(for: request),
               let fingerprints = FingerprintFileData.fromJSON(cachedResponse.data),
               fingerprints.isValid {
                referenceCache[episodeUuid] = fingerprints
                saveToDiskCache(fingerprints, episodeUuid: episodeUuid, isClient: false)
                FileLog.shared.addMessage("FingerprintService: loaded reference fingerprints from URL cache for \(episodeUuid)")
                return fingerprints
            }

            // Fetch from network
            do {
                FileLog.shared.addMessage("FingerprintService: fetching reference fingerprints for \(episodeUuid)")
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    FileLog.shared.addMessage("FingerprintService: server returned non-200 for \(episodeUuid)")
                    return nil
                }

                guard let fingerprints = FingerprintFileData.fromJSON(data),
                      fingerprints.isValid else {
                    FileLog.shared.addMessage("FingerprintService: failed to decode fingerprints for \(episodeUuid)")
                    return nil
                }

                // Cache the response
                let cachedResponse = CachedURLResponse(response: response, data: data)
                urlCache.storeCachedResponse(cachedResponse, for: request)
                referenceCache[episodeUuid] = fingerprints
                saveToDiskCache(fingerprints, episodeUuid: episodeUuid, isClient: false)

                FileLog.shared.addMessage("FingerprintService: successfully fetched reference fingerprints for \(episodeUuid)")
                return fingerprints
            } catch {
                FileLog.shared.addMessage("FingerprintService: network error fetching fingerprints for \(episodeUuid): \(error.localizedDescription)")
                return nil
            }
        }

        fetchTasks[episodeUuid] = task
        return try await task.value
    }

    /// Get cached reference fingerprints without fetching from network.
    ///
    /// - Parameter episodeUuid: The episode UUID.
    /// - Returns: Cached fingerprint data, or nil if not cached.
    public func getCachedReferenceFingerprints(episodeUuid: String) -> FingerprintFileData? {
        if let cached = referenceCache[episodeUuid] {
            return cached
        }

        if let diskCached = loadFromDiskCache(episodeUuid: episodeUuid, isClient: false) {
            referenceCache[episodeUuid] = diskCached
            return diskCached
        }

        return nil
    }

    // MARK: - Client Fingerprints

    /// Generate client fingerprints from a downloaded episode's audio file.
    ///
    /// - Parameter episode: The episode to generate fingerprints for.
    /// - Returns: Dictionary of checkpoints (timestamp -> hash string), or nil if generation failed.
    @discardableResult
    public func generateClientFingerprints(for episode: BaseEpisode) async -> [String: String]? {
        #if os(iOS)
        let episodeUuid = episode.uuid

        // Check memory cache first
        if let cached = clientCache[episodeUuid] {
            FileLog.shared.addMessage("FingerprintService: returning cached client fingerprints for \(episodeUuid)")
            return cached
        }

        // Check disk cache
        if let diskCached = loadClientFingerprintsFromDisk(episodeUuid: episodeUuid) {
            clientCache[episodeUuid] = diskCached
            FileLog.shared.addMessage("FingerprintService: loaded client fingerprints from disk for \(episodeUuid)")
            return diskCached
        }

        // Check for in-flight generation
        if let existingTask = generationTasks[episodeUuid] {
            return await existingTask.value
        }

        // Create new generation task
        let task = Task<[String: String]?, Never> {
            defer { generationTasks[episodeUuid] = nil }

            let filePath = episode.pathToDownloadedFile(pathFinder: DownloadManager.shared)
            let fileURL = URL(fileURLWithPath: filePath)

            guard FileManager.default.fileExists(atPath: filePath) else {
                FileLog.shared.addMessage("FingerprintService: audio file not found for \(episodeUuid)")
                return nil
            }

            FileLog.shared.addMessage("FingerprintService: generating client fingerprints for \(episodeUuid)")

            do {
                let audioData = try Data(contentsOf: fileURL)

                let windows = try fingerprinter.fingerprintDataWindowed(
                    data: audioData,
                    windowDurationMs: 10000,  // 10 seconds
                    windowIntervalMs: 2000     // 2 seconds
                )

                guard !windows.isEmpty else {
                    FileLog.shared.addMessage("FingerprintService: fingerprint generation returned empty for \(episodeUuid)")
                    return nil
                }

                // Convert windowed fingerprints to checkpoints dictionary
                var checkpoints: [String: String] = [:]
                for window in windows {
                    let timestampSec = window.timestampMs / 1000
                    let hashString = window.hashes.map { String($0) }.joined(separator: ",")
                    checkpoints[String(timestampSec)] = hashString
                }

                clientCache[episodeUuid] = checkpoints
                saveClientFingerprintsToDisk(checkpoints, episodeUuid: episodeUuid)

                FileLog.shared.addMessage("FingerprintService: generated \(checkpoints.count) client fingerprints for \(episodeUuid)")
                return checkpoints
            } catch {
                FileLog.shared.addMessage("FingerprintService: error generating fingerprints for \(episodeUuid): \(error.localizedDescription)")
                return nil
            }
        }

        generationTasks[episodeUuid] = task
        return await task.value
        #else
        // Fingerprint library not available on this platform
        FileLog.shared.addMessage("FingerprintService: Fingerprint library not available, cannot generate client fingerprints")
        return nil
        #endif
    }

    /// Get cached client fingerprints without generating.
    ///
    /// - Parameter episodeUuid: The episode UUID.
    /// - Returns: Cached client fingerprints, or nil if not cached.
    public func getCachedClientFingerprints(episodeUuid: String) -> [String: String]? {
        if let cached = clientCache[episodeUuid] {
            return cached
        }

        if let diskCached = loadClientFingerprintsFromDisk(episodeUuid: episodeUuid) {
            clientCache[episodeUuid] = diskCached
            return diskCached
        }

        return nil
    }

    // MARK: - Cache Management

    /// Clear all cached fingerprints for an episode.
    ///
    /// - Parameter episodeUuid: The episode UUID.
    public func clearCache(for episodeUuid: String) {
        referenceCache.removeValue(forKey: episodeUuid)
        clientCache.removeValue(forKey: episodeUuid)

        // Remove disk cache files
        let referenceFile = diskCacheDirectory.appendingPathComponent("\(episodeUuid)_reference.json")
        let clientFile = diskCacheDirectory.appendingPathComponent("\(episodeUuid)_client.json")
        try? FileManager.default.removeItem(at: referenceFile)
        try? FileManager.default.removeItem(at: clientFile)
    }

    /// Clear all cached fingerprints.
    public func clearAllCaches() {
        referenceCache.removeAll()
        clientCache.removeAll()
        urlCache.removeAllCachedResponses()

        // Clear disk cache
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Disk Cache Helpers

    private nonisolated func saveToDiskCache(_ data: FingerprintFileData, episodeUuid: String, isClient: Bool) {
        let suffix = isClient ? "client" : "reference"
        let fileURL = diskCacheDirectory.appendingPathComponent("\(episodeUuid)_\(suffix).json")

        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: fileURL)
        } catch {
            FileLog.shared.addMessage("FingerprintService: failed to save fingerprints to disk: \(error.localizedDescription)")
        }
    }

    private nonisolated func loadFromDiskCache(episodeUuid: String, isClient: Bool) -> FingerprintFileData? {
        let suffix = isClient ? "client" : "reference"
        let fileURL = diskCacheDirectory.appendingPathComponent("\(episodeUuid)_\(suffix).json")

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return FingerprintFileData.fromJSON(data)
    }

    private nonisolated func saveClientFingerprintsToDisk(_ checkpoints: [String: String], episodeUuid: String) {
        let fileURL = diskCacheDirectory.appendingPathComponent("\(episodeUuid)_client.json")

        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(checkpoints)
            try jsonData.write(to: fileURL)
        } catch {
            FileLog.shared.addMessage("FingerprintService: failed to save client fingerprints to disk: \(error.localizedDescription)")
        }
    }

    private nonisolated func loadClientFingerprintsFromDisk(episodeUuid: String) -> [String: String]? {
        let fileURL = diskCacheDirectory.appendingPathComponent("\(episodeUuid)_client.json")

        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        do {
            return try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Convenience Extensions

extension FingerprintService {
    /// Check if reference fingerprints are available for an episode.
    ///
    /// - Parameter episodeUuid: The episode UUID.
    /// - Returns: True if fingerprints are cached.
    public func hasReferenceFingerprints(episodeUuid: String) -> Bool {
        getCachedReferenceFingerprints(episodeUuid: episodeUuid) != nil
    }

    /// Check if client fingerprints are available for an episode.
    ///
    /// - Parameter episodeUuid: The episode UUID.
    /// - Returns: True if fingerprints are cached.
    public func hasClientFingerprints(episodeUuid: String) -> Bool {
        getCachedClientFingerprints(episodeUuid: episodeUuid) != nil
    }
}
