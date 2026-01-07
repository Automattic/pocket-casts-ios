import Foundation
import PocketCastsUtils
#if os(iOS)
import Fingerprint
#endif

/// Fingerprint matching utilities that use the native Rust implementation.
/// The drift compensation algorithm is implemented in the Rust library to ensure
/// consistency across all platforms (Android, iOS, etc.).
public enum FingerprintMatcher {

    /// Default similarity threshold for considering a match valid.
    public static let defaultSimilarityThreshold: Float = 0.7

    /// Default maximum drift for hash position alignment.
    public static let defaultMaxDrift: Int = 10

    /// Parse a comma-separated fingerprint string into a list of unsigned integers.
    public static func parseFingerprint(_ fpString: String) -> [UInt32] {
        fpString.split(separator: ",")
            .compactMap { UInt32($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Compare two fingerprints and return a similarity score (0.0 to 1.0).
    /// Uses the native Rust implementation with drift compensation.
    ///
    /// - Parameters:
    ///   - fp1: First fingerprint hash array.
    ///   - fp2: Second fingerprint hash array.
    ///   - maxDrift: Maximum number of hash positions to shift for alignment (0 = no drift).
    /// - Returns: Similarity score between 0.0 (completely different) and 1.0 (identical).
    public static func compare(_ fp1: [UInt32], _ fp2: [UInt32], maxDrift: Int = 0) -> Float {
        guard !fp1.isEmpty, !fp2.isEmpty else { return 0 }

        #if os(iOS)
        return compareHashesWithDrift(
            hashes1: fp1,
            hashes2: fp2,
            maxDrift: UInt32(maxDrift)
        )
        #else
        return 0.0
        #endif
    }

    /// Find the best matching checkpoints in target data for a query fingerprint.
    ///
    /// - Parameters:
    ///   - queryHashes: Query fingerprint hash array.
    ///   - targetData: Target fingerprint data containing checkpoints.
    ///   - maxDrift: Maximum drift for comparison.
    ///   - topN: Number of top matches to return.
    /// - Returns: List of top matching results sorted by similarity (highest first).
    public static func findTopMatches(
        queryHashes: [UInt32],
        targetData: FingerprintFileData,
        maxDrift: Int = defaultMaxDrift,
        topN: Int = 3
    ) -> [FingerprintMatchResult] {
        var results: [FingerprintMatchResult] = []

        for (tsStr, fpStr) in targetData.checkpoints {
            guard let timestamp = Float(tsStr) else { continue }
            let targetHashes = parseFingerprint(fpStr)
            guard !targetHashes.isEmpty else { continue }

            let score = compare(queryHashes, targetHashes, maxDrift: maxDrift)
            results.append(FingerprintMatchResult(timestamp: timestamp, similarity: score))
        }

        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(topN)
            .map { $0 }
    }

    /// Find the best matching checkpoint above a similarity threshold.
    ///
    /// - Parameters:
    ///   - queryHashes: Query fingerprint hash array.
    ///   - targetData: Target fingerprint data containing checkpoints.
    ///   - maxDrift: Maximum drift for comparison.
    ///   - threshold: Minimum similarity score to consider a valid match.
    /// - Returns: The best match if it meets the threshold, or nil otherwise.
    public static func findBestMatch(
        queryHashes: [UInt32],
        targetData: FingerprintFileData,
        maxDrift: Int = defaultMaxDrift,
        threshold: Float = defaultSimilarityThreshold
    ) -> FingerprintMatchResult? {
        let matches = findTopMatches(
            queryHashes: queryHashes,
            targetData: targetData,
            maxDrift: maxDrift,
            topN: 1
        )

        guard let best = matches.first, best.similarity >= threshold else {
            return nil
        }

        return best
    }

    /// Find the timestamp offset between client and reference fingerprints.
    ///
    /// - Parameters:
    ///   - clientTimestamp: Timestamp in seconds from client audio.
    ///   - clientCheckpoints: Client fingerprint checkpoints.
    ///   - referenceData: Reference fingerprint data from server.
    ///   - maxDrift: Maximum drift for comparison.
    ///   - threshold: Minimum similarity for valid match.
    /// - Returns: The matched reference timestamp if found, or nil.
    public static func findReferenceTimestamp(
        clientTimestamp: Float,
        clientCheckpoints: [String: String],
        referenceData: FingerprintFileData,
        maxDrift: Int = defaultMaxDrift,
        threshold: Float = defaultSimilarityThreshold
    ) -> Float? {
        // Find the checkpoint closest to client timestamp
        let clientTimestampInt = Int(clientTimestamp)
        guard let clientCheckpointKey = clientCheckpoints.keys
            .min(by: { abs(Int($0) ?? 0 - clientTimestampInt) < abs(Int($1) ?? 0 - clientTimestampInt) }),
            let clientFpString = clientCheckpoints[clientCheckpointKey] else {
            return nil
        }

        let clientHashes = parseFingerprint(clientFpString)
        guard !clientHashes.isEmpty else { return nil }

        // Find best match in reference fingerprints
        guard let match = findBestMatch(
            queryHashes: clientHashes,
            targetData: referenceData,
            maxDrift: maxDrift,
            threshold: threshold
        ) else {
            FileLog.shared.addMessage("Fingerprints: No match found for client \(String(format: "%.1f", clientTimestamp))s (threshold: \(String(format: "%.2f", threshold)))")
            return nil
        }

        let diff = clientTimestamp - match.timestamp
        FileLog.shared.addMessage("Fingerprints: Fingerprint match: client \(String(format: "%.1f", clientTimestamp))s -> original \(String(format: "%.1f", match.timestamp))s (diff: \(String(format: "%.1f", diff))s, similarity: \(String(format: "%.2f", match.similarity)))")

        return match.timestamp
    }
}
