import AVFoundation
import Fingerprint
import Foundation
import PocketCastsUtils

/// Runs the continuous transcript fingerprint pass: owns the checkpoint matcher
/// for the episode being prepared, stream-decodes the local audio chunk by chunk,
/// and hands each batch of scored candidates back to be committed.
///
/// Cancel the `Task` driving `run` and the loops bail at the next chunk boundary
/// or the next sleep.
actor FingerprintStreamProcessor {

    private var matcher: FingerprintWindowMatcher?

    /// Builds the matcher for `reference` — one FFI call per checkpoint. Returns
    /// the number of usable checkpoints, or nil when the reference has none.
    func prepare(reference: ReferenceFingerprint, episodeUuid: String, audioDuration: Double) -> Int? {
        guard let matcher = try? FingerprintWindowMatcher(
            reference: reference,
            episodeUuid: episodeUuid,
            audioDuration: audioDuration
        ) else {
            return nil
        }
        self.matcher = matcher
        return matcher.checkpointCount
    }

    /// Stream-decode the local file, push PCM into the streaming fingerprinter
    /// chunk-by-chunk, and hand off each batch of windows as soon as it's
    /// emitted. We start near the current playback position (snapped to the
    /// window grid so window timestamps line up with the reference checkpoints),
    /// so highlighting becomes usable for what the listener is actually hearing
    /// without waiting for the entire file to be processed.
    ///
    /// - Parameters:
    ///   - currentPlaybackTime: read once per chunk for the lookahead throttle.
    ///   - commit: called on every non-empty batch, in decode order.
    func run(
        audioFileURL: URL,
        isStreaming: Bool,
        startingAt startSeconds: Double,
        currentPlaybackTime: @escaping @Sendable () async -> Double,
        commit: @escaping @Sendable (MatchBatch) async -> Void
    ) async throws {
        guard let matcher else { throw FingerprintStreamError.noUsableCheckpoints }
        if isStreaming {
            try await runGrowing(
                audioFileURL: audioFileURL,
                startSeconds: startSeconds,
                matcher: matcher,
                currentPlaybackTime: currentPlaybackTime,
                commit: commit
            )
        } else {
            try await runComplete(
                audioFileURL: audioFileURL,
                startSeconds: startSeconds,
                matcher: matcher,
                currentPlaybackTime: currentPlaybackTime,
                commit: commit
            )
        }
    }

    // MARK: - Complete file

    private func runComplete(
        audioFileURL: URL,
        startSeconds: Double,
        matcher: FingerprintWindowMatcher,
        currentPlaybackTime: @Sendable () async -> Double,
        commit: @Sendable (MatchBatch) async -> Void
    ) async throws {
        // Force the reader to hand us non-interleaved Float32 PCM so
        // `buffer.floatChannelData` is never nil regardless of the on-disk format.
        let audioFile = try AVAudioFile(
            forReading: audioFileURL,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let format = audioFile.processingFormat
        let channels = UInt16(format.channelCount)

        let startFrame = AVAudioFramePosition(startSeconds * format.sampleRate)
        if startFrame > 0, startFrame < audioFile.length {
            audioFile.framePosition = startFrame
        }

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

        var interleaved: [Float] = []
        while audioFile.framePosition < audioFile.length {
            try Task.checkCancellation()
            let nextChunkStartSeconds = Double(audioFile.framePosition) / format.sampleRate
            try await throttleIfBeyondLookahead(
                nextChunkStartSeconds: nextChunkStartSeconds,
                currentPlaybackTime: currentPlaybackTime
            )
            try audioFile.read(into: buffer, frameCount: chunkFrames)
            if buffer.frameLength == 0 { break }

            FingerprintPCM.interleave(buffer, into: &interleaved)
            let windows = streamer.pushSamplesF32(samples: interleaved, channels: channels)
            if !windows.isEmpty {
                await commit(matcher.batch(for: windows, startOffset: startSeconds))
            }
        }

        try Task.checkCancellation()
        let tail = streamer.flush()
        if !tail.isEmpty {
            await commit(matcher.batch(for: tail, startOffset: startSeconds))
        }
    }

    // MARK: - Growing streaming buffer

    /// Streaming-buffer variant. Same pipeline, but the file may not exist yet
    /// when we start, and grows while we read — so we reopen `AVAudioFile` each
    /// pass to refresh its length, seek to where we left off, and consume
    /// whatever new frames are available. Exits when the buffer has been stalled
    /// for `bufferGrowMaxStallSeconds` or the task is cancelled; a later
    /// playback-progress restart picks up again if the listener keeps playing.
    private func runGrowing(
        audioFileURL: URL,
        startSeconds: Double,
        matcher: FingerprintWindowMatcher,
        currentPlaybackTime: @Sendable () async -> Double,
        commit: @Sendable (MatchBatch) async -> Void
    ) async throws {
        let pollCadence = FingerprintConstants.bufferGrowPollCadenceSeconds
        let maxStallSeconds = FingerprintConstants.bufferGrowMaxStallSeconds
        let trailingMarginSeconds = FingerprintConstants.bufferGrowTrailingMarginSeconds

        var streamer: StreamingWindowedFingerprinter?
        var format: AVAudioFormat?
        var buffer: AVAudioPCMBuffer?
        var chunkFrames: AVAudioFrameCount = 0
        var lastProcessedFrame: AVAudioFramePosition = 0
        var stallAccumSeconds: Double = 0
        var announcedFileAppeared = false
        var totalFramesRead: AVAudioFramePosition = 0
        var windowsEmitted = 0
        var interleaved: [Float] = []

        FileLog.shared.addMessage(
            "FingerprintTimingManager: streaming grow-loop starting at \(String(format: "%.1f", startSeconds))s "
                + "(buffer path: \(audioFileURL.lastPathComponent))"
        )

        while true {
            try Task.checkCancellation()

            guard FileManager.default.fileExists(atPath: audioFileURL.path) else {
                // Streaming buffer not created yet — AVPlayer will write it
                // once it actually begins fetching bytes.
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try await Task.sleep(for: .seconds(pollCadence))
                continue
            }

            let audioFile: AVAudioFile
            do {
                audioFile = try AVAudioFile(
                    forReading: audioFileURL,
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
            } catch {
                // Partial frame at the tail can make `AVAudioFile` refuse to
                // open momentarily — wait and retry.
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try await Task.sleep(for: .seconds(pollCadence))
                continue
            }

            if !announcedFileAppeared {
                announcedFileAppeared = true
                FileLog.shared.addMessage(
                    "FingerprintTimingManager: streaming buffer opened "
                        + "(length \(audioFile.length) frames @ \(Int(audioFile.processingFormat.sampleRate))Hz, "
                        + "\(audioFile.processingFormat.channelCount)ch)"
                )
            }

            if streamer == nil {
                let fmt = audioFile.processingFormat
                let desiredStartFrame = max(0, AVAudioFramePosition(startSeconds * fmt.sampleRate))

                // The streaming buffer on disk is sequential from byte 0, so the
                // local file's frame `N` maps to audio timeline `N / sampleRate`.
                // If the buffer hasn't grown to `startSeconds` yet, reading from
                // the current tail and tagging those windows as `startSeconds +
                // windowTimestamp` would attribute them to the wrong reference
                // time — matches would fail. Wait until the file covers the
                // target position, then anchor `lastProcessedFrame` exactly there.
                guard audioFile.length >= desiredStartFrame else {
                    stallAccumSeconds += pollCadence
                    if stallAccumSeconds >= maxStallSeconds { break }
                    try await Task.sleep(for: .seconds(pollCadence))
                    continue
                }

                format = fmt
                streamer = StreamingWindowedFingerprinter(
                    sampleRate: UInt32(fmt.sampleRate),
                    channels: UInt16(fmt.channelCount),
                    windowDurationMs: FingerprintConstants.windowDurationMs,
                    windowIntervalMs: FingerprintConstants.windowIntervalMs
                )
                chunkFrames = AVAudioFrameCount(fmt.sampleRate * FingerprintConstants.streamChunkSeconds)
                guard let allocated = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: chunkFrames) else {
                    throw FingerprintStreamError.bufferAllocationFailed
                }
                buffer = allocated
                lastProcessedFrame = desiredStartFrame
            }

            guard let fmt = format, let streamer, let buffer else { break }

            let trailingMarginFrames = AVAudioFramePosition(trailingMarginSeconds * fmt.sampleRate)
            let safeEnd = audioFile.length - trailingMarginFrames

            guard lastProcessedFrame < safeEnd else {
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try await Task.sleep(for: .seconds(pollCadence))
                continue
            }

            audioFile.framePosition = lastProcessedFrame
            let framesAvailable = AVAudioFrameCount(safeEnd - lastProcessedFrame)
            let framesToRead = min(framesAvailable, chunkFrames)

            let nextChunkStartSeconds = Double(lastProcessedFrame) / fmt.sampleRate
            try await throttleIfBeyondLookahead(
                nextChunkStartSeconds: nextChunkStartSeconds,
                currentPlaybackTime: currentPlaybackTime
            )

            do {
                try audioFile.read(into: buffer, frameCount: framesToRead)
            } catch {
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try await Task.sleep(for: .seconds(pollCadence))
                continue
            }

            if buffer.frameLength == 0 {
                stallAccumSeconds += pollCadence
                if stallAccumSeconds >= maxStallSeconds { break }
                try await Task.sleep(for: .seconds(pollCadence))
                continue
            }

            stallAccumSeconds = 0
            let framesJustRead = audioFile.framePosition - lastProcessedFrame
            lastProcessedFrame = audioFile.framePosition
            totalFramesRead += framesJustRead

            FingerprintPCM.interleave(buffer, into: &interleaved)
            let windows = streamer.pushSamplesF32(samples: interleaved, channels: UInt16(fmt.channelCount))
            if !windows.isEmpty {
                windowsEmitted += windows.count
                await commit(matcher.batch(for: windows, startOffset: startSeconds))
            }
        }

        try Task.checkCancellation()
        if let streamer {
            let tail = streamer.flush()
            if !tail.isEmpty {
                windowsEmitted += tail.count
                await commit(matcher.batch(for: tail, startOffset: startSeconds))
            }
        }

        let readSeconds = (format.map { Double(totalFramesRead) / $0.sampleRate }) ?? 0
        FileLog.shared.addMessage(
            "FingerprintTimingManager: streaming grow-loop ending — "
                + "read \(String(format: "%.1f", readSeconds))s of audio, "
                + "emitted \(windowsEmitted) windows, "
                + "stall accum \(String(format: "%.1f", stallAccumSeconds))s"
        )
    }

    // MARK: - Throttle

    /// Yield briefly when the next chunk to fingerprint sits more than
    /// `lookaheadSeconds` ahead of the listener's current playback time. This
    /// keeps coverage growing to EOF — the chunk is **never** skipped — while
    /// bounding peak CPU on long episodes the listener hasn't reached yet.
    /// Capping the loop instead of throttling it (the prior POC-546 attempt)
    /// dropped tail regions from the mapping and broke tap-to-seek for any cue
    /// further than `lookaheadSeconds` ahead.
    private func throttleIfBeyondLookahead(
        nextChunkStartSeconds: Double,
        currentPlaybackTime: @Sendable () async -> Double
    ) async throws {
        let lead = nextChunkStartSeconds - (await currentPlaybackTime())
        guard lead > FingerprintConstants.lookaheadSeconds else { return }
        try await Task.sleep(for: .seconds(FingerprintConstants.outsideLookaheadSleepSeconds))
    }
}
