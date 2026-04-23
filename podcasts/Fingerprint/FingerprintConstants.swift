import Foundation

enum FingerprintConstants {
    /// If consecutive playback-progress notifications differ by more than this,
    /// treat it as a seek/skip and restart fingerprint generation at the new position
    /// so coverage stays close to what the listener is hearing.
    static let restartDeltaSeconds: Double = 10

    /// When playback drifts further than this beyond the already-mapped range,
    /// restart fingerprint generation from the new position. Also acts as the
    /// slack window around the mapped range before we consider playback "outside".
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
    /// Reserved for future streaming support — not yet referenced, but the hook
    /// lives here so the knob is discoverable when we pick that path up.
    static let bufferGrowPollCadenceSeconds: TimeInterval = 1.0

    /// Score at or above which the debug overlay shows green (high confidence).
    static let debugOverlayHighScoreThreshold: Float = 0.85

    /// Score at or above which the debug overlay shows orange (medium confidence).
    static let debugOverlayMediumScoreThreshold: Float = 0.7

    /// Minimum number of mapping entries before the timing manager transitions to `.active`.
    static let minimumCoverageForActive: Int = 2

    /// Residual tolerance, in seconds, on the rate-≈1 drift filter. This is **not**
    /// a jump size cap — a jump of any magnitude is accepted as long as the next
    /// candidate projects from the jump position at rate 1 within this tolerance.
    /// What this rejects is "candidate sits off any recent rate-1 line", i.e.
    /// jump-around noise.
    static let driftToleranceSeconds: Double = 5

    /// Number of consecutive rate-≈1 candidates required to establish the first
    /// trusted anchor before we have one to project from.
    static let driftBootstrapCount: Int = 3
}
