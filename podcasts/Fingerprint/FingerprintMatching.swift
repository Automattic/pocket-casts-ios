import Accelerate
import AVFoundation
import Fingerprint
import Foundation
import PocketCastsUtils

/// What one batch of fingerprint windows produced once the score and dominance
/// gates had their say.
struct MatchBatch: Sendable {

    #if DEBUG
    struct Rejection: Sendable {
        let entry: TimeMappingEntry
        let reason: String
    }
    #endif

    /// Candidates that passed the gates, in window order, ready for the drift filter.
    var candidates: [TimeMappingEntry] = []

    #if DEBUG
    /// Candidates the gates dropped, so the debug overlay can visualize "matcher
    /// fired but we didn't trust it" distinctly from "matcher never fired here".
    var rejections: [Rejection] = []
    #endif
}

enum FingerprintStreamError: Error {
    case bufferAllocationFailed
    /// The requested audio region isn't present in the local file yet (a
    /// streaming episode whose buffer hasn't reached the target region).
    case regionUnavailable
    /// The reference decoded but yielded no usable checkpoints.
    case noUsableCheckpoints
}

/// The library `CheckpointMatcher` for one episode, plus the score/dominance
/// gates every window has to clear. Each processor builds and keeps its own.
final class FingerprintWindowMatcher {

    private let matcher: CheckpointMatcher
    let checkpointCount: Int

    /// Builds a matcher populated from every usable checkpoint in `reference`.
    /// Fails when the reference has no usable checkpoints.
    init(reference: ReferenceFingerprint, episodeUuid: String, audioDuration: Double) throws {
        let checkpointDuration = reference.checkpointDurationSeconds
        let libraryCheckpoints = reference.libraryCheckpoints()

        FileLog.shared.addMessage(
            "FingerprintTimingManager: reference for \(episodeUuid) — "
                + "totalDuration=\(reference.totalDuration)s, "
                + "checkpointInterval=\(reference.checkpointInterval), "
                + "checkpointDuration=\(reference.checkpointDuration)s, "
                + "timestampQuantum=\(reference.timestampQuantum), "
                + "raw=\(reference.checkpoints.count), decoded=\(libraryCheckpoints.count)"
        )
        if let first = libraryCheckpoints.first, let last = libraryCheckpoints.last {
            FileLog.shared.addMessage(
                "FingerprintTimingManager: checkpoint timestamps span "
                    + "\(String(format: "%.1f", first.timestampSeconds))s..\(String(format: "%.1f", last.timestampSeconds))s "
                    + "(audio duration \(String(format: "%.1f", audioDuration))s)"
            )
        }

        guard !libraryCheckpoints.isEmpty else { throw FingerprintStreamError.noUsableCheckpoints }

        let matcher = CheckpointMatcher()
        for checkpoint in libraryCheckpoints {
            matcher.add(
                timestamp: checkpoint.timestampSeconds,
                hashes: checkpoint.hashes,
                duration: checkpointDuration
            )
        }
        self.matcher = matcher
        self.checkpointCount = libraryCheckpoints.count
    }

    /// Runs each window through the matcher and applies the score/dominance
    /// gates. The expensive half of the pipeline.
    func batch(for windows: [WindowedFingerprint], startOffset: Double) -> MatchBatch {
        var batch = MatchBatch()
        #if DEBUG
        var bestScoreOverall: Float = 0
        var nonZeroScoreCount = 0
        var scoreSum: Float = 0
        #endif

        for window in windows {
            // Pull top-2 so we can check how dominant the winner is — ambiguous
            // wins (top-1 barely beats top-2) are the hallmark of correlated
            // false positives from non-matching audio.
            let matches = matcher.findTopMatches(queryHashes: window.hashes, maxResults: 2)
            guard let best = matches.first else { continue }

            #if DEBUG
            if best.score > 0 {
                nonZeroScoreCount += 1
                scoreSum += best.score
            }
            if best.score > bestScoreOverall { bestScoreOverall = best.score }
            #endif
            guard best.score >= FingerprintConstants.matchScoreThreshold else { continue }

            let absolutePlaybackTime = startOffset + Double(window.timestampMs) / 1000.0
            let candidate = TimeMappingEntry(
                playbackTime: absolutePlaybackTime,
                referenceTime: Double(best.timestamp),
                score: best.score
            )

            if best.score < FingerprintConstants.driftAnchorScoreThreshold {
                #if DEBUG
                batch.rejections.append(
                    .init(entry: candidate, reason: "low score \(String(format: "%.2f", best.score))")
                )
                #endif
                continue
            }
            let runnerUpScore = matches.dropFirst().first?.score ?? 0
            if best.score - runnerUpScore < FingerprintConstants.driftScoreDominanceGap {
                #if DEBUG
                batch.rejections.append(
                    .init(
                        entry: candidate,
                        reason: "ambiguous top-1 vs top-2 "
                            + "(\(String(format: "%.2f", best.score)) vs \(String(format: "%.2f", runnerUpScore)))"
                    )
                )
                #endif
                continue
            }

            batch.candidates.append(candidate)
        }

        #if DEBUG
        let avgNonZero = nonZeroScoreCount > 0 ? scoreSum / Float(nonZeroScoreCount) : 0
        FileLog.shared.addMessage(
            "FingerprintTimingManager: processed \(windows.count) windows, "
                + "\(batch.candidates.count) passed the gates "
                + "(bestScore: \(String(format: "%.3f", bestScoreOverall)), "
                + "nonZero: \(nonZeroScoreCount), avgNonZero: \(String(format: "%.3f", avgNonZero)))"
        )
        #endif
        return batch
    }
}

enum FingerprintPCM {

    /// Interleaves the buffer's planar Float32 channels into `scratch`, reusing
    /// its storage across chunks. `scratch` is resized only when the sample
    /// count changes (in practice once, plus once more for a short final
    /// chunk), so a decode loop allocates O(1) arrays instead of one per chunk.
    static func interleave(_ buffer: AVAudioPCMBuffer, into scratch: inout [Float]) {
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameCount > 0, channelCount > 0,
              let channelData = buffer.floatChannelData else {
            scratch.removeAll(keepingCapacity: true)
            return
        }

        let sampleCount = frameCount * channelCount
        if scratch.count != sampleCount {
            scratch = [Float](repeating: 0, count: sampleCount)
        }
        scratch.withUnsafeMutableBufferPointer { dst in
            guard let base = dst.baseAddress else { return }
            if channelCount == 1 {
                base.update(from: channelData[0], count: frameCount)
                return
            }
            // Strided vector copy (add-zero) — one vDSP pass per channel
            // instead of a scalar store per sample.
            var zero: Float = 0
            for ch in 0..<channelCount {
                vDSP_vsadd(channelData[ch], 1, &zero, base + ch, vDSP_Stride(channelCount), vDSP_Length(frameCount))
            }
        }
    }
}
