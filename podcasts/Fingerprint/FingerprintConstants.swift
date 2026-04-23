import Foundation

enum FingerprintConstants {
    /// Seconds of playback jump that triggers a re-fingerprint from the current position.
    /// Reserved for future streaming support — unused on the downloaded-files path, which
    /// fingerprints the whole file upfront.
    static let restartDeltaSeconds: Double = 10

    /// Seconds of margin beyond the mapped range before triggering a restart.
    /// Reserved for future streaming support — unused on the downloaded-files path.
    static let playbackRangeMarginSeconds: Double = 30

    /// Minimum match score to accept a fingerprint match result.
    static let matchScoreThreshold: Float = 0.5

    /// Duration of each windowed fingerprint produced during live matching, in milliseconds.
    static let windowDurationMs: UInt32 = 8000

    /// Interval between windowed fingerprints produced during live matching, in milliseconds.
    static let windowIntervalMs: UInt32 = 2000

    /// Seconds of decoded PCM read per AVAudioFile chunk during streaming
    /// fingerprint generation. Smaller = more responsive UI, larger = less per-call overhead.
    static let streamChunkSeconds: Double = 5

    /// Seconds between polls when waiting for the streaming buffer to grow.
    /// Reserved for future streaming support — unused on the downloaded-files path.
    static let bufferGrowPollCadenceSeconds: TimeInterval = 1.0

    /// Score at or above which the debug overlay shows green (high confidence).
    static let debugOverlayHighScoreThreshold: Float = 0.85

    /// Score at or above which the debug overlay shows orange (medium confidence).
    static let debugOverlayMediumScoreThreshold: Float = 0.7

    /// Minimum number of mapping entries before the timing manager transitions to `.active`.
    static let minimumCoverageForActive: Int = 2
}
