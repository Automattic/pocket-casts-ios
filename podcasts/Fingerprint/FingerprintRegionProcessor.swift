import AVFoundation
import Fingerprint
import Foundation
import PocketCastsUtils

/// Runs the bounded, one-shot resolves — chapter taps and bookmarks alike.
///
/// Kept separate from `FingerprintStreamProcessor` so a resolve with a spinner in
/// front of it can't queue behind the continuous run, which lasts the length of an
/// episode. The two one-shots share this one because both are bounded — a
/// bookmark's long budget is spent waiting for its buffer, not decoding.
///
/// Every run matches into a **local** scratch accumulator, so nothing the
/// transcript highlighter depends on is ever touched.
actor FingerprintRegionProcessor {

    /// Fingerprint `[startSeconds, endSeconds]` of `audioFileURL` and match it
    /// against `reference` into a fresh scratch accumulator.
    ///
    /// Unlike the continuous run this stops at `endSeconds` (not EOF) and skips
    /// the lookahead throttle. Throws `.regionUnavailable` when the local file
    /// doesn't yet reach `startSeconds` (a streaming episode whose buffer hasn't
    /// advanced to the target region).
    func match(
        audioFileURL: URL,
        reference: ReferenceFingerprint,
        episodeUuid: String,
        audioDuration: Double,
        startSeconds: Double,
        endSeconds: Double
    ) async throws -> MappingAccumulator {
        let matcher = try FingerprintWindowMatcher(
            reference: reference,
            episodeUuid: episodeUuid,
            audioDuration: audioDuration
        )

        let audioFile = try AVAudioFile(
            forReading: audioFileURL,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let format = audioFile.processingFormat
        let channels = UInt16(format.channelCount)

        let fileDurationSeconds = Double(audioFile.length) / format.sampleRate
        guard startSeconds < fileDurationSeconds else { throw FingerprintStreamError.regionUnavailable }

        let startFrame = AVAudioFramePosition(startSeconds * format.sampleRate)
        if startFrame > 0 { audioFile.framePosition = startFrame }
        let endFrame = min(AVAudioFramePosition(endSeconds * format.sampleRate), audioFile.length)

        let streamer = StreamingWindowedFingerprinter(
            sampleRate: UInt32(format.sampleRate),
            channels: channels,
            windowDurationMs: FingerprintConstants.windowDurationMs,
            windowIntervalMs: FingerprintConstants.windowIntervalMs
        )

        let chunkFrames = AVAudioFrameCount(format.sampleRate * FingerprintConstants.streamChunkSeconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrames) else {
            throw FingerprintStreamError.bufferAllocationFailed
        }

        var scratch = MappingAccumulator()
        var interleaved: [Float] = []
        while audioFile.framePosition < endFrame {
            try Task.checkCancellation()
            let framesRemaining = AVAudioFrameCount(endFrame - audioFile.framePosition)
            try audioFile.read(into: buffer, frameCount: min(framesRemaining, chunkFrames))
            if buffer.frameLength == 0 { break }

            FingerprintPCM.interleave(buffer, into: &interleaved)
            let windows = streamer.pushSamplesF32(samples: interleaved, channels: channels)
            if !windows.isEmpty {
                Self.apply(matcher.batch(for: windows, startOffset: startSeconds), to: &scratch)
            }
            await Task.yield()
        }

        try Task.checkCancellation()
        let tail = streamer.flush()
        if !tail.isEmpty {
            Self.apply(matcher.batch(for: tail, startOffset: startSeconds), to: &scratch)
        }
        return scratch
    }

    /// Wait for a still-downloading streaming buffer to cover `coveringSeconds`
    /// of audio, polling as it grows.
    ///
    /// `MediaExporterResourceLoaderDelegate` caches with a single un-ranged
    /// request appended to disk, so the buffer is always a prefix of the episode
    /// and `AVAudioFile.length` tracks exactly how much of it is local — the same
    /// property the grow-loop anchors on.
    ///
    /// Returns once covered, or early when the file stops growing, the deadline
    /// passes, or the task is cancelled. There's deliberately no failure signal:
    /// the bounded fingerprint clamps to whatever is readable, so matching a
    /// short prefix of the window still beats returning nothing.
    func waitForBufferedRegion(audioFileURL: URL, coveringSeconds: Double, deadline: Date) async {
        let pollCadence = FingerprintConstants.bufferGrowPollCadenceSeconds
        var stallSeconds: Double = 0
        var lastLength: AVAudioFramePosition = -1

        while !Task.isCancelled, Date() < deadline {
            // The buffer may not exist yet, and a partial frame at the tail can make
            // `AVAudioFile` refuse to open momentarily — both read as "no growth".
            if let audioFile = try? AVAudioFile(
                forReading: audioFileURL,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            ) {
                let bufferedSeconds = Double(audioFile.length) / audioFile.processingFormat.sampleRate
                if bufferedSeconds >= coveringSeconds {
                    FileLog.shared.addMessage(
                        "FingerprintTimingManager: streaming buffer covers the search window "
                            + "(\(String(format: "%.1f", bufferedSeconds))s buffered)"
                    )
                    return
                }
                if audioFile.length > lastLength {
                    lastLength = audioFile.length
                    stallSeconds = 0
                }
            }

            stallSeconds += pollCadence
            if stallSeconds >= FingerprintConstants.bookmarkSeekBufferStallSeconds {
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming buffer stopped growing short of the "
                        + "search window — fingerprinting the \(max(0, lastLength)) frames that arrived"
                )
                return
            }
            try? await Task.sleep(for: .seconds(pollCadence))
        }
    }

    private static func apply(_ batch: MatchBatch, to accumulator: inout MappingAccumulator) {
        #if DEBUG
        for rejection in batch.rejections {
            accumulator.record(rejection.entry, reason: rejection.reason)
        }
        #endif
        for candidate in batch.candidates {
            accumulator.consider(candidate)
        }
    }
}
