import Foundation
import PocketCastsUtils

/// Maps client audio timestamps to original episode timestamps using fingerprint matching.
/// This handles the timestamp offset caused by Dynamic Ad Insertion (DAI).
public final class TimestampMapper {
    /// The reference fingerprints from the server (original episode without ads).
    private var referenceFingerprints: FingerprintFileData?

    /// The client fingerprints generated from downloaded audio (may include ads).
    private var clientFingerprints: [String: String]?

    /// The current matched offset between client and reference timestamps.
    private var currentOffset: TimeInterval = 0

    /// The last successfully matched client timestamp.
    private var lastMatchedClientTimestamp: TimeInterval = 0

    /// The last successfully matched reference timestamp.
    private var lastMatchedReferenceTimestamp: TimeInterval = 0

    /// Whether we have a valid match to use for offset calculation.
    private var hasValidMatch: Bool = false

    /// Similarity threshold for considering a match valid.
    private let similarityThreshold: Float

    /// Maximum drift for fingerprint comparison.
    private let maxDrift: Int

    /// The checkpoint interval in seconds (how often fingerprints are sampled).
    private var checkpointInterval: Int = 2

    /// Lock for thread-safe access.
    private let lock = NSLock()

    /// Timestamp of the last fingerprint match operation.
    private var lastMatchTime: Date?

    /// Minimum interval between match operations (in seconds).
    private let matchInterval: TimeInterval = 0.5

    /// Interval for re-alignment (in seconds).
    /// Even with a valid match, we re-align periodically to correct drift.
    private let realignmentInterval: TimeInterval = 10.0

    public init(
        similarityThreshold: Float = FingerprintMatcher.defaultSimilarityThreshold,
        maxDrift: Int = FingerprintMatcher.defaultMaxDrift
    ) {
        self.similarityThreshold = similarityThreshold
        self.maxDrift = maxDrift
    }

    // MARK: - Configuration

    /// Update the fingerprints used for timestamp mapping.
    ///
    /// - Parameters:
    ///   - reference: Reference fingerprints from the server.
    ///   - client: Client fingerprints from downloaded audio.
    public func updateFingerprints(
        reference: FingerprintFileData?,
        client: [String: String]?
    ) {
        lock.lock()
        defer { lock.unlock() }

        referenceFingerprints = reference
        clientFingerprints = client

        if let reference = reference {
            checkpointInterval = reference.checkpointInterval
        }

        // Reset match state when fingerprints change
        resetMatchStateInternal()

        if reference != nil && client != nil {
            FileLog.shared.addMessage("TimestampMapper: updated fingerprints - reference: \(reference?.checkpoints.count ?? 0), client: \(client?.count ?? 0)")
        }
    }

    /// Reset the match state, clearing any cached offset.
    public func resetMatchState() {
        lock.lock()
        defer { lock.unlock() }

        resetMatchStateInternal()
    }

    /// Internal reset without lock - call only when lock is already held.
    private func resetMatchStateInternal() {
        currentOffset = 0
        lastMatchedClientTimestamp = 0
        lastMatchedReferenceTimestamp = 0
        hasValidMatch = false
        lastMatchTime = nil
    }

    // MARK: - Timestamp Mapping

    /// Map a client timestamp to the original episode timestamp.
    ///
    /// This method uses fingerprint matching to find the corresponding position
    /// in the original episode, accounting for ad insertions.
    ///
    /// - Parameter clientTime: The current playback position in the client audio.
    /// - Returns: The corresponding timestamp in the original episode, or nil if no match found.
    public func mapClientTimestamp(_ clientTime: TimeInterval) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }

        guard let reference = referenceFingerprints else {
            // No reference fingerprints available, return original timestamp
            return clientTime
        }

        // Handle downloaded mode with pre-calculated fingerprints
        guard let client = clientFingerprints, !client.isEmpty else {
            // No client fingerprints available, return original timestamp
            return clientTime
        }

        // If we have a recent valid match, use interpolation for smooth playback
        // But re-align periodically to correct any drift, or when position changes (seeking)
        if hasValidMatch {
            let timeSinceLastMatch = clientTime - lastMatchedClientTimestamp
            let interpolatedTime = lastMatchedReferenceTimestamp + timeSinceLastMatch
            // Re-align if: seeking backward, seeking forward significantly, or 10s elapsed
            let needsRealignment = timeSinceLastMatch < 0 || timeSinceLastMatch >= realignmentInterval

            if !needsRealignment {
                // Return interpolated time if it seems reasonable
                if interpolatedTime >= 0 && interpolatedTime <= reference.totalDuration {
                    return interpolatedTime
                }
            } else {
                FileLog.shared.addMessage("TimestampMapper: fingerprint mapClientTimestamp - re-aligning (position delta: \(String(format: "%.1f", timeSinceLastMatch))s), clientTime: \(clientTime)s")
            }
        }

        // Throttle match operations to avoid excessive computation
        if let lastMatch = lastMatchTime,
           Date().timeIntervalSince(lastMatch) < matchInterval {
            // Return best guess based on current state
            if hasValidMatch {
                let timeSinceLastMatch = clientTime - lastMatchedClientTimestamp
                return lastMatchedReferenceTimestamp + timeSinceLastMatch
            }
            return nil
        }

        // Perform fingerprint matching
        if let matchedTimestamp = performMatch(clientTime: Float(clientTime), reference: reference, client: client) {
            lastMatchedClientTimestamp = clientTime
            lastMatchedReferenceTimestamp = TimeInterval(matchedTimestamp)
            currentOffset = clientTime - TimeInterval(matchedTimestamp)
            hasValidMatch = true
            lastMatchTime = Date()

            return TimeInterval(matchedTimestamp)
        }

        lastMatchTime = Date()

        // No match found
        if hasValidMatch {
            // Use last known offset for continuity
            let timeSinceLastMatch = clientTime - lastMatchedClientTimestamp
            return lastMatchedReferenceTimestamp + timeSinceLastMatch
        }

        return nil
    }

    /// Check if fingerprint matching is available for the current episode.
    public var isMatchingAvailable: Bool {
        lock.lock()
        defer { lock.unlock() }

        return referenceFingerprints != nil && clientFingerprints != nil
    }

    /// Get the current offset between client and reference timestamps.
    /// Positive means client is ahead (ads were inserted before this point).
    public var timestampOffset: TimeInterval {
        lock.lock()
        defer { lock.unlock() }

        return currentOffset
    }

    // MARK: - Private Methods

    private func performMatch(
        clientTime: Float,
        reference: FingerprintFileData,
        client: [String: String]
    ) -> Float? {
        // Find the checkpoint closest to client timestamp
        let clientTimestampInt = Int(clientTime)

        // Find nearby checkpoints (within 2 checkpoint intervals)
        let searchRange = checkpointInterval * 2
        let checkpointsToTry = client.keys
            .compactMap { Int($0) }
            .filter { abs($0 - clientTimestampInt) <= searchRange }
            .sorted { abs($0 - clientTimestampInt) < abs($1 - clientTimestampInt) }

        for checkpointKey in checkpointsToTry {
            guard let clientFpString = client[String(checkpointKey)] else { continue }

            let clientHashes = FingerprintMatcher.parseFingerprint(clientFpString)
            guard !clientHashes.isEmpty else { continue }

            // Find best match in reference fingerprints
            if let match = FingerprintMatcher.findBestMatch(
                queryHashes: clientHashes,
                targetData: reference,
                maxDrift: maxDrift,
                threshold: similarityThreshold
            ) {
                // Adjust for the offset between the checkpoint and the actual client time
                let checkpointOffset = clientTime - Float(checkpointKey)
                let adjustedTimestamp = match.timestamp + checkpointOffset

                if match.similarity < similarityThreshold {
                    return nil
                }

                let diff = clientTime - adjustedTimestamp
                FileLog.shared.addMessage("Fingerprints: Fingerprint match: client \(String(format: "%.1f", clientTime))s -> original \(String(format: "%.1f", adjustedTimestamp))s (diff: \(String(format: "%.1f", diff))s, similarity: \(String(format: "%.2f", match.similarity)))")

                return adjustedTimestamp
            }
        }

        return nil
    }
}

// MARK: - Debug Helpers

extension TimestampMapper {
    /// Get a debug description of the current state.
    public var debugDescription: String {
        lock.lock()
        defer { lock.unlock() }

        return """
        TimestampMapper:
          - Reference checkpoints: \(referenceFingerprints?.checkpoints.count ?? 0)
          - Client checkpoints: \(clientFingerprints?.count ?? 0)
          - Has valid match: \(hasValidMatch)
          - Current offset: \(currentOffset)s
          - Last client timestamp: \(lastMatchedClientTimestamp)s
          - Last reference timestamp: \(lastMatchedReferenceTimestamp)s
        """
    }
}
