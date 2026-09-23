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

    /// Interval between windowed fingerprints emitted during live matching, in
    /// milliseconds. Deliberately FINER than the reference's 2s checkpoint grid
    /// (oversampling). A dynamic ad whose duration isn't a 2s multiple phase-shifts
    /// our windows off that grid, so at a 2s stride every following window straddles
    /// two checkpoints and matches neither cleanly (the post-mid-roll failure).
    /// Emitting every 1s guarantees that for any ad offset a window lands within
    /// ~0.5s of a checkpoint — that well-aligned window scores dominantly and
    /// commits, while the off-phase ones straddle and are dropped by the existing
    /// dominance gate. No score inflation, no gate changes, so precision is
    /// unchanged elsewhere. Cost: ~2x window hashing/matching. Halve again (500) for
    /// ~0.25s alignment if 1s doesn't score dominantly enough post-ad.
    static let windowIntervalMs: UInt32 = 1000

    /// Seconds of decoded PCM read per AVAudioFile chunk during streaming
    /// fingerprint generation. Smaller = more responsive UI, larger = less per-call overhead.
    static let streamChunkSeconds: Double = 5

    /// Seconds between polls when waiting for the streaming buffer to grow
    /// while fingerprinting a not-yet-downloaded episode.
    static let bufferGrowPollCadenceSeconds: TimeInterval = 1.0

    /// Give up the streaming grow-loop after this many consecutive seconds
    /// without new bytes — listener likely paused or the network stalled.
    /// A later `handlePlaybackProgress` restart will pick us back up.
    static let bufferGrowMaxStallSeconds: TimeInterval = 60

    /// Trailing audio the grow-loop refuses to read, in seconds. The last sliver
    /// of a growing file can be a partial MP3 frame that decodes to noise —
    /// waiting until the file has grown past it keeps false-positive
    /// fingerprint matches out of the mapping.
    static let bufferGrowTrailingMarginSeconds: Double = 1.0

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

    /// Minimum matcher score for a match to even reach the drift filter. Stricter
    /// than `matchScoreThreshold` on purpose: that one is the matcher's minimum-
    /// confidence floor; this is the filter's "is this actually good enough to
    /// build a mapping on" bar. Kept just above the red/orange boundary on the
    /// debug overlay so solid-orange matches (which do come from real content)
    /// still get in, while the red noise does not.
    static let driftAnchorScoreThreshold: Float = 0.65

    /// Minimum score gap between the top-1 and top-2 matcher candidates for a
    /// window. Real matches tend to have a clear winner; correlated false
    /// positives from non-matching audio score similarly against several nearby
    /// reference windows, so the gap is small. Small value here — we just want
    /// to reject near-ties, not demand a huge dominance (which would kill real
    /// matches whose nearby reference windows also score decently).
    static let driftScoreDominanceGap: Float = 0.05

    /// Distance ahead of `PlaybackManager.currentTime()` within which the streaming
    /// fingerprint loop runs at full speed. Beyond this lead, the loop still
    /// processes every chunk (so coverage still grows to EOF), but it sleeps
    /// `outsideLookaheadSleepSeconds` between chunks to bound peak CPU usage.
    /// **Not a hard cap** — chunks are never skipped.
    static let lookaheadSeconds: Double = 60

    /// Sleep inserted between fingerprint chunks when the next chunk's start is
    /// further than `lookaheadSeconds` ahead of the listener's current time.
    /// Bounds peak CPU on long episodes without dropping any region from the
    /// mapping, so tap-to-seek's dense-coverage invariant is preserved.
    static let outsideLookaheadSleepSeconds: TimeInterval = 0.5

    /// Fraction of the reference timeline that a cached mapping must cover for
    /// it to be loaded as a complete replacement for the streaming fingerprint
    /// pass. Anything less and the cache is ignored: partial caches that seed a
    /// short-circuit are how the prior POC-546 attempt got stuck in `.preparing`.
    static let fullCoverageThreshold: Double = 0.95

    /// Persistent cache schema version. Bump when the on-disk shape changes so
    /// older files are silently discarded on the next load.
    static let mappingCacheSchemaVersion: Int = 2

    /// Highlighting is opt-in: a transcript word is only highlighted while playback
    /// sits between two committed anchors no further apart than this. Real content
    /// commits anchors every second or two, and sparse "quick red" gaps within
    /// matched audio stay under this bound, so highlighting tracks continuously.
    /// Dynamic ads and other unmatched audio open a much wider gap (or leave no
    /// committed anchor ahead at all), so the instant playback crosses the last
    /// matched anchor the gap jumps past this and highlighting stops — no ad
    /// detection, no lag. Comfortably below a typical ad break (≥15s).
    static let highlightMaxGapSeconds: Double = 8

    // MARK: - On-demand chapter seek

    /// Cold path (no existing mapping — the common case when a generated chapter is
    /// tapped from the player). Forward audio searched starting at the chapter's raw
    /// reference time. Because dynamic-ad offset only accumulates, the true playback
    /// position is always ≥ the reference time; this caps how far ahead we look, and
    /// hence worst-case decode/CPU/latency, before falling back to a raw skip.
    static let onDemandSeekColdBudgetSeconds: Double = 240

    /// Warm path, target ahead of the listener. Extra audio searched past the
    /// rate-1 lower bound (`P + (T − R_now)`) to absorb ad insertions between the
    /// current position and the target.
    static let onDemandSeekForwardBudgetSeconds: Double = 120

    /// Warm path, target behind the listener. Cap on the `[T, T + offset_now]`
    /// search window when the current offset is large.
    static let onDemandSeekBackwardMaxSeconds: Double = 180

    /// Minimum committed anchors in the one-shot scratch mapping before a resolved
    /// playback time is trusted. Mirrors `minimumCoverageForActive` — two anchors
    /// give a locally-consistent rate-1 segment to interpolate on.
    static let onDemandSeekMinAnchors: Int = 2

    /// Hard timeout for a one-shot chapter resolve. On expiry the resolve is
    /// cancelled and the caller falls back to a raw skip, so a pathological decode
    /// can't hang the tap behind an indefinite spinner.
    static let onDemandSeekTimeoutSeconds: TimeInterval = 5

    // MARK: - Bookmark position resolve

    /// Local audio region fingerprinted around a bookmark's playback position when
    /// resolving it to the reference timeline. Unlike the chapter seek there's no
    /// searching involved, so the region only needs to be big enough to commit
    /// anchors bracketing the position.
    static let bookmarkResolveBackwardSeconds: Double = 35
    static let bookmarkResolveForwardSeconds: Double = 10

    /// Minimum committed anchors in the one-shot scratch mapping before a
    /// resolved reference time is trusted. Mirrors `onDemandSeekMinAnchors`.
    static let bookmarkResolveMinAnchors: Int = 2

    /// Hard timeout for a one-shot bookmark position resolve. On expiry the
    /// caller falls back to the raw playback time.
    static let bookmarkResolveTimeoutSeconds: TimeInterval = 5

    // MARK: - Bookmark playback resolve

    /// Hard timeout for resolving a bookmark's reference time back to a playback
    /// position. Far longer than `onDemandSeekTimeoutSeconds` because a chapter's
    /// audio is already local by definition while a bookmark's often isn't: playing
    /// it starts a stream-and-cache download and the region being matched only
    /// arrives once that prefix reaches it. This also bounds how long a played
    /// bookmark keeps the player paused (and its row's spinner up) before falling
    /// back to the stored time.
    static let bookmarkSeekTimeoutSeconds: TimeInterval = 25

    /// How much of that budget may be spent waiting for a still-downloading buffer
    /// to cover the search window. The remainder is left for the decode, which has
    /// to fit inside the timeout above to deliver anything at all.
    static let bookmarkSeekBufferWaitSeconds: TimeInterval = 15

    /// Stop waiting early once the buffer stops growing for this long — no network,
    /// a stalled download, or an episode that never caches to disk at all (HLS,
    /// video, user uploads).
    static let bookmarkSeekBufferStallSeconds: TimeInterval = 8
}
