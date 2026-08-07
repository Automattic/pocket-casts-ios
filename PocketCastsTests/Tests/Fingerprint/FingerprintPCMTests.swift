import AVFoundation
import XCTest

@testable import podcasts

/// Planar → interleaved conversion. The decode loop reuses one scratch array
/// across every chunk of an episode, so both the layout and the reuse are load
/// bearing.
final class FingerprintPCMTests: XCTestCase {

    func testMonoBufferIsCopiedThrough() throws {
        let buffer = try Self.buffer(channels: [[0.1, 0.2, 0.3]])
        var scratch: [Float] = []

        FingerprintPCM.interleave(buffer, into: &scratch)

        XCTAssertEqual(scratch, [0.1, 0.2, 0.3])
    }

    func testStereoChannelsAreInterleaved() throws {
        let buffer = try Self.buffer(channels: [[1, 2, 3], [-1, -2, -3]])
        var scratch: [Float] = []

        FingerprintPCM.interleave(buffer, into: &scratch)

        XCTAssertEqual(scratch, [1, -1, 2, -2, 3, -3])
    }

    func testScratchIsFullyOverwrittenWhenReusedAtTheSameSize() throws {
        var scratch: [Float] = []
        FingerprintPCM.interleave(try Self.buffer(channels: [[1, 2, 3], [-1, -2, -3]]), into: &scratch)

        FingerprintPCM.interleave(try Self.buffer(channels: [[7, 8, 9], [-7, -8, -9]]), into: &scratch)

        XCTAssertEqual(scratch, [7, -7, 8, -8, 9, -9])
    }

    func testScratchIsResizedWhenTheChunkShrinks() throws {
        var scratch: [Float] = []
        FingerprintPCM.interleave(try Self.buffer(channels: [[1, 2, 3]]), into: &scratch)

        FingerprintPCM.interleave(try Self.buffer(channels: [[4]]), into: &scratch)

        XCTAssertEqual(scratch, [4])
    }

    /// A zero-length read has to leave nothing behind — feeding the previous
    /// chunk's samples to the fingerprinter again would invent audio.
    func testEmptyBufferClearsTheScratch() throws {
        var scratch: [Float] = []
        FingerprintPCM.interleave(try Self.buffer(channels: [[1, 2, 3]]), into: &scratch)

        FingerprintPCM.interleave(try Self.buffer(channels: [[]]), into: &scratch)

        XCTAssertTrue(scratch.isEmpty)
    }

    private static func buffer(channels: [[Float]]) throws -> AVAudioPCMBuffer {
        let format = try XCTUnwrap(AVAudioFormat(
            standardFormatWithSampleRate: 44100,
            channels: AVAudioChannelCount(channels.count)
        ))
        let frames = channels[0].count
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(max(frames, 1))
        ))
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = try XCTUnwrap(buffer.floatChannelData)
        for (channel, samples) in channels.enumerated() {
            for (frame, sample) in samples.enumerated() {
                data[channel][frame] = sample
            }
        }
        return buffer
    }
}
