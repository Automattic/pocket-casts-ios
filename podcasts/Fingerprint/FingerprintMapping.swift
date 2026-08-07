import Foundation
import PocketCastsUtils

/// A committed anchor: a position on the listener's playback timeline and the
/// reference-timeline position the fingerprint matcher tied it to.
struct TimeMappingEntry: Sendable {
    let playbackTime: Double
    let referenceTime: Double
    let score: Float

    init(playbackTime: Double, referenceTime: Double, score: Float = 0) {
        self.playbackTime = playbackTime
        self.referenceTime = referenceTime
        self.score = score
    }
}

/// The two sorted views of a committed mapping. The timing manager republishes
/// this after every commit; interpolation and the highlight gate read it directly.
struct MappingSnapshot: Sendable {
    var playbackToReference: [TimeMappingEntry] = []
    var referenceToPlayback: [TimeMappingEntry] = []

    var isEmpty: Bool { playbackToReference.isEmpty }

    mutating func insert(_ entry: TimeMappingEntry) {
        let playbackIndex = playbackToReference.sortedInsertionIndex { $0.playbackTime < entry.playbackTime }
        playbackToReference.insert(entry, at: playbackIndex)

        let referenceIndex = referenceToPlayback.sortedInsertionIndex { $0.referenceTime < entry.referenceTime }
        referenceToPlayback.insert(entry, at: referenceIndex)
    }
}

/// The mutable state a fingerprint match run accumulates: the committed mapping
/// plus the drift filter's rolling state. A value type so the continuous
/// transcript path and the one-shot resolves can each run the identical matching
/// pipeline against their own accumulator, without the one-shot ever touching the
/// mapping the highlighter depends on.
struct MappingAccumulator: Sendable {
    var snapshot = MappingSnapshot()
    var filterLastTrusted: TimeMappingEntry?
    var filterCandidatePool: [TimeMappingEntry] = []

    #if DEBUG
    /// Candidates that reached the drift filter but were rejected. The debug
    /// overlay uses this to distinguish "matcher never fired here" from
    /// "matcher fired but everything was filtered out as noise".
    private(set) var rejections: [TimeMappingEntry] = []
    private static let rejectionCap = 500
    #endif

    /// Filter state is reset (but the mapping kept) when the stream restarts at a
    /// new position: the new stream's first matches live in a region that has no
    /// rate relationship to the old trusted anchor.
    mutating func resetFilterState() {
        filterLastTrusted = nil
        filterCandidatePool.removeAll()
    }

    // MARK: - Drift Filter

    /// Routes a score-passing candidate through the drift filter. Returns the
    /// number of entries actually inserted into the mapping this call.
    ///
    /// Invariant the filter enforces:
    /// **no anchor — bootstrap or post-jump — is admitted until we've seen
    /// `driftBootstrapCount` consecutive rate-≈1 candidates in a row.**
    ///
    /// - Fast path: candidate is in-trend with `filterLastTrusted` → commit
    ///   immediately, flush any pooled candidates as rejections (a prior jump
    ///   attempt that didn't pan out turned out to be noise).
    /// - Slow path: candidate goes into `filterCandidatePool`. Once the pool's
    ///   tail is `driftBootstrapCount` consecutive consistent entries, commit
    ///   them all and drop anything before as rejections. Otherwise evict the
    ///   oldest and keep rolling.
    ///
    /// This is the same rule for the initial bootstrap (no `lastTrusted` yet)
    /// and for post-trusted jumps, so a single lucky pair can never admit an
    /// anchor.
    @discardableResult
    mutating func consider(_ candidate: TimeMappingEntry) -> Int {
        if let trusted = filterLastTrusted, Self.isInTrend(candidate, relativeTo: trusted) {
            // Sequential continuation. Anything that had collected in the pool
            // was a jump attempt that never stabilized — reject it.
            flushPoolAsRejected(reason: "returned to trend")
            snapshot.insert(candidate)
            filterLastTrusted = candidate
            return 1
        }

        filterCandidatePool.append(candidate)
        let n = FingerprintConstants.driftBootstrapCount

        guard filterCandidatePool.count >= n else { return 0 }

        let recent = Array(filterCandidatePool.suffix(n))
        if Self.formsConsistentSequence(recent) {
            // Confirmed new anchor. Anything older in the pool is noise.
            let keepStart = filterCandidatePool.count - n
            if keepStart > 0 {
                for entry in filterCandidatePool.prefix(keepStart) {
                    record(entry, reason: "pool evicted by confirmed anchor")
                }
            }
            #if DEBUG
            FileLog.shared.addMessage(
                "FingerprintTimingManager: drift filter confirmed anchor "
                    + "at playback \(String(format: "%.1f", recent[0].playbackTime))s → "
                    + "\(String(format: "%.1f", recent[recent.count - 1].playbackTime))s "
                    + "(\(n) consistent)"
            )
            #endif
            for entry in recent {
                snapshot.insert(entry)
            }
            filterLastTrusted = recent.last
            filterCandidatePool.removeAll()
            return n
        }

        // Not consistent yet — evict oldest and keep waiting for the window to
        // roll onto a consistent stretch.
        let evicted = filterCandidatePool.removeFirst()
        record(evicted, reason: "pool evicted, no consistent run")
        return 0
    }

    /// Note a candidate the pipeline dropped. DEBUG-only bookkeeping for the
    /// overlay; a no-op in release builds.
    mutating func record(_ entry: TimeMappingEntry, reason: String) {
        #if DEBUG
        FileLog.shared.addMessage(
            "FingerprintTimingManager: drift filter dropped \(reason) "
                + "at playback \(String(format: "%.1f", entry.playbackTime))s "
                + "(matched reference \(String(format: "%.1f", entry.referenceTime))s)"
        )
        rejections.append(entry)
        if rejections.count > Self.rejectionCap {
            rejections.removeFirst(rejections.count - Self.rejectionCap)
        }
        #endif
    }

    private mutating func flushPoolAsRejected(reason: String) {
        for entry in filterCandidatePool {
            record(entry, reason: reason)
        }
        filterCandidatePool.removeAll()
    }

    /// Two entries are in-trend when `Δreference ≈ Δplayback` (rate ≈ 1),
    /// within `driftToleranceSeconds` of residual slack.
    private static func isInTrend(_ candidate: TimeMappingEntry, relativeTo anchor: TimeMappingEntry) -> Bool {
        let deltaPlayback = candidate.playbackTime - anchor.playbackTime
        let deltaReference = candidate.referenceTime - anchor.referenceTime
        return abs(deltaReference - deltaPlayback) <= FingerprintConstants.driftToleranceSeconds
    }

    private static func formsConsistentSequence(_ entries: [TimeMappingEntry]) -> Bool {
        guard entries.count >= 2 else { return true }
        for i in 1..<entries.count where !isInTrend(entries[i], relativeTo: entries[i - 1]) {
            return false
        }
        return true
    }
}

// MARK: - Array Sorted Insertion

private extension Array {
    func sortedInsertionIndex(isOrderedBefore: (Element) -> Bool) -> Int {
        var lo = 0
        var hi = count
        while lo < hi {
            let mid = (lo + hi) / 2
            if isOrderedBefore(self[mid]) {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }
}
