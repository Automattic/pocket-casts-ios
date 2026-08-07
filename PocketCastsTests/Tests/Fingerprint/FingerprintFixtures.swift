import AVFoundation
import Fingerprint
import Foundation

@testable import podcasts

/// The two on-disk inputs a fingerprint run needs: an audio file, and a reference
/// fingerprint built from that same audio the way the server builds one from the
/// publisher's copy of the episode.
enum FingerprintFixtures {

    static let sampleRate: Double = 44100

    /// The reference grid `makeReference` fingerprints on, matching the shape of a
    /// server-generated reference: a checkpoint every 2 s, each covering 8 s.
    static let checkpointIntervalSeconds = 2
    static let checkpointDurationSeconds = 8

    enum FixtureError: Error {
        case bufferAllocationFailed
        case openForWritingFailed(String)
        case openForReadingFailed(String)
        case readFailed(String)
    }

    // MARK: - Audio

    /// Writes `seconds` of deterministic audio to `url`.
    ///
    /// Every 250 ms the tones change, drawn from a seeded generator, so no two
    /// moments in the file share a spectrum — the property a fingerprint relies on
    /// to tie a window to one point on the timeline. A little broadband noise
    /// underneath keeps the spectrum from being three bare spikes.
    static func writeAudio(seconds: Double, to url: URL) throws {
        // The file is only closed (and its header finalized) when the last
        // reference to it goes away, so it stays scoped to this pool — the
        // caller's next move is to open the same path for reading.
        try autoreleasepool {
            try write(seconds: seconds, to: url)
        }
    }

    private static func write(seconds: Double, to url: URL) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forWriting: url, settings: settings)
        } catch {
            throw FixtureError.openForWritingFailed("\(error)")
        }
        let format = file.processingFormat

        let segmentFrames = AVAudioFrameCount(sampleRate * 0.25)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: segmentFrames) else {
            throw FixtureError.bufferAllocationFailed
        }

        // Two octaves of semitones from A3 up, so consecutive segments are always
        // clearly distinguishable in the spectrum.
        let scale = (0..<24).map { 220.0 * pow(2.0, Double($0) / 12.0) }
        var random = SeededGenerator(seed: 0xF1_9E_2B_71)

        let totalFrames = Int(seconds * sampleRate)
        var writtenFrames = 0
        while writtenFrames < totalFrames {
            let frames = min(Int(segmentFrames), totalFrames - writtenFrames)
            let tones = (0..<3).map { _ in scale[random.nextIndex(upperBound: scale.count)] }

            buffer.frameLength = AVAudioFrameCount(frames)
            guard let samples = buffer.floatChannelData?[0] else { throw FixtureError.bufferAllocationFailed }
            for frame in 0..<frames {
                let time = Double(writtenFrames + frame) / sampleRate
                var value = 0.0
                for tone in tones {
                    value += sin(2 * .pi * tone * time)
                }
                samples[frame] = Float(value * 0.25 + (random.nextUnit() - 0.5) * 0.04)
            }

            try file.write(from: buffer)
            writtenFrames += frames
        }
    }

    // MARK: - Reference fingerprint

    /// Fingerprints `url` on a checkpoint grid and encodes the result as the
    /// compact-v2 JSON the app downloads from the server, so a run against this
    /// audio should map every window onto its own timestamp.
    static func makeReference(
        forAudioAt url: URL,
        checkpointIntervalSeconds: Int = checkpointIntervalSeconds,
        checkpointDurationSeconds: Int = checkpointDurationSeconds
    ) throws -> Data {
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        } catch {
            throw FixtureError.openForReadingFailed("\(error)")
        }
        let format = file.processingFormat
        let windowDurationMs = UInt32(checkpointDurationSeconds * 1000)

        let fingerprinter = StreamingWindowedFingerprinter(
            sampleRate: UInt32(format.sampleRate),
            channels: UInt16(format.channelCount),
            windowDurationMs: windowDurationMs,
            windowIntervalMs: UInt32(checkpointIntervalSeconds * 1000)
        )

        let chunkFrames = AVAudioFrameCount(format.sampleRate * 5)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrames) else {
            throw FixtureError.bufferAllocationFailed
        }

        var windows: [WindowedFingerprint] = []
        // Bounded by `length` rather than by a zero-length read: `read` throws at
        // EOF instead of returning no frames.
        while file.framePosition < file.length {
            do {
                try file.read(into: buffer, frameCount: chunkFrames)
            } catch {
                throw FixtureError.readFailed("\(error)")
            }
            if buffer.frameLength == 0 { break }
            guard let channel = buffer.floatChannelData?[0] else { break }
            let samples = Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
            windows += fingerprinter.pushSamplesF32(samples: samples, channels: UInt16(format.channelCount))
        }
        windows += fingerprinter.flush()

        // A trailing partial window covers less audio than the grid promises, so
        // it would anchor a matching window to the wrong reference time.
        windows = windows.filter { $0.durationMs == windowDurationMs }

        var checkpoints: [[Any]] = []
        var previousSecond = 0
        for window in windows {
            let second = Int(window.timestampMs) / 1000
            guard checkpoints.isEmpty || second > previousSecond else { continue }
            checkpoints.append([second - previousSecond, base64(hashes: window.hashes)])
            previousSecond = second
        }

        let json: [String: Any] = [
            "format": ReferenceFingerprint.supportedFormat,
            "total_duration": Double(file.length) / format.sampleRate,
            "checkpoint_interval": checkpointIntervalSeconds,
            "checkpoint_duration": checkpointDurationSeconds,
            "timestamp_quantum": 1,
            "checkpoints": checkpoints
        ]
        return try JSONSerialization.data(withJSONObject: json)
    }

    /// Little-endian `UInt32` packing, the inverse of `ReferenceFingerprint.libraryCheckpoints()`.
    private static func base64(hashes: [UInt32]) -> String {
        var payload = Data(capacity: hashes.count * 4)
        for hash in hashes {
            payload.append(UInt8(truncatingIfNeeded: hash))
            payload.append(UInt8(truncatingIfNeeded: hash >> 8))
            payload.append(UInt8(truncatingIfNeeded: hash >> 16))
            payload.append(UInt8(truncatingIfNeeded: hash >> 24))
        }
        return payload.base64EncodedString()
    }
}

/// SplitMix64 — the fixtures need to be byte-identical from run to run, which
/// rules out `SystemRandomNumberGenerator`.
private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func nextIndex(upperBound: Int) -> Int {
        Int(next() % UInt64(upperBound))
    }

    /// A value in `0..<1`.
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}
