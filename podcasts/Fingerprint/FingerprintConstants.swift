import Foundation

enum FingerprintConstants {
    /// Seconds of playback jump that triggers a re-fingerprint from the current position.
    static let restartDeltaSeconds: Double = 10

    /// Seconds of margin beyond the mapped range before triggering a restart.
    static let playbackRangeMarginSeconds: Double = 30

    /// Minimum match score to accept a fingerprint match result.
    static let matchScoreThreshold: Float = 0.5

    /// Number of fingerprint windows processed per batch.
    static let batchSize: Int = 50

    /// Seconds between polls when waiting for the streaming buffer to grow.
    static let bufferGrowPollCadenceSeconds: TimeInterval = 1.0

    /// Score at or above which the debug overlay shows green (high confidence).
    static let debugOverlayHighScoreThreshold: Float = 0.85

    /// Score at or above which the debug overlay shows orange (medium confidence).
    static let debugOverlayMediumScoreThreshold: Float = 0.7

    /// Minimum number of mapping entries before the timing manager transitions to `.active`.
    static let minimumCoverageForActive: Int = 2
}
