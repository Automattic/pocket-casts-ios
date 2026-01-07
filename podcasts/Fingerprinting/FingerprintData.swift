import Foundation

/// Data structure for fingerprint JSON files from the server.
public struct FingerprintFileData: Codable, Sendable {
    /// Status of the fingerprint file ("ok" for valid files).
    public let status: String

    /// Total duration of the audio in seconds.
    public let totalDuration: Double

    /// Interval between checkpoints in seconds.
    public let checkpointInterval: Int

    /// Duration of each checkpoint window in seconds.
    public let checkpointDuration: Int

    /// Dictionary of checkpoints where keys are timestamp strings (in seconds)
    /// and values are comma-separated hash strings.
    public let checkpoints: [String: String]

    enum CodingKeys: String, CodingKey {
        case status
        case totalDuration = "total_duration"
        case checkpointInterval = "checkpoint_interval"
        case checkpointDuration = "checkpoint_duration"
        case checkpoints
    }

    /// Decode from JSON data.
    /// - Parameter data: JSON data to decode.
    /// - Returns: Decoded FingerprintFileData or nil if decoding fails.
    public static func fromJSON(_ data: Data) -> FingerprintFileData? {
        let decoder = JSONDecoder()
        return try? decoder.decode(FingerprintFileData.self, from: data)
    }

    /// Check if the fingerprint data is valid and ready to use.
    public var isValid: Bool {
        status == "ok" && !checkpoints.isEmpty
    }
}

/// Result of a fingerprint match (local type to avoid conflict with UniFFI MatchResult).
public struct FingerprintMatchResult: Sendable {
    /// Timestamp in seconds from the reference fingerprints.
    public let timestamp: Float

    /// Similarity score between 0.0 (completely different) and 1.0 (identical).
    public let similarity: Float

    public init(timestamp: Float, similarity: Float) {
        self.timestamp = timestamp
        self.similarity = similarity
    }
}
