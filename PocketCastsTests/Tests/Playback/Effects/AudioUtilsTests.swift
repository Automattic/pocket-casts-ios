import XCTest
@testable import podcasts
import AVFoundation
import Accelerate

final class AudioUtilsTests: XCTestCase {

    var audioBuffer: AudioBuffer!

    override func setUp() async throws {
        audioBuffer = sampleBuffer()
    }

    override func tearDown() async throws {
        cleanUpAudioBuffer(buffer: &audioBuffer)
    }

    private var bufferFormat: AVAudioFormat = {
        var asbd = AudioStreamBasicDescription(
            mSampleRate: 44100.0,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
            mBytesPerPacket: UInt32(MemoryLayout<Float32>.size),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(MemoryLayout<Float32>.size),
            mChannelsPerFrame: 1,
            mBitsPerChannel: UInt32(8 * MemoryLayout<Float32>.size),
            mReserved: 0
        )

        return AVAudioFormat(streamDescription: &asbd)!
    }()

    private func sampleBuffer() -> AudioBuffer {
        let samples: [Float32] = [-8, -4, -0, 2, 4, 8]

        var audioBuffer = AudioBuffer()
        audioBuffer.mNumberChannels = 1 // Mono audio
        audioBuffer.mDataByteSize = UInt32(samples.count * MemoryLayout<Float32>.size)
        audioBuffer.mData = UnsafeMutableRawPointer.allocate(byteCount: Int(audioBuffer.mDataByteSize), alignment: MemoryLayout<Float32>.alignment)

        audioBuffer.mData?.initializeMemory(as: Float32.self, repeating: 0, count: samples.count)
        audioBuffer.mData?.copyMemory(from: samples, byteCount: Int(audioBuffer.mDataByteSize))

        return audioBuffer
    }

    // Function to deallocate memory and clean up
    private func cleanUpAudioBuffer(buffer: inout AudioBuffer) {
        buffer.mData?.deallocate()
        buffer.mData = nil
    }

    private func audioBufferToAVAudioPCMBuffer(audioBuffer: AudioBuffer, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // Calculate the number of frames in the AudioBuffer
        let frameLength = audioBuffer.mDataByteSize / format.streamDescription.pointee.mBytesPerFrame

        // Create an AVAudioPCMBuffer with the same format and frame capacity
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameLength)) else {
            return nil
        }

        // Copy the data from the AudioBuffer to the AVAudioPCMBuffer
        pcmBuffer.frameLength = AVAudioFrameCount(frameLength)
        let audioBufferData = audioBuffer.mData!.assumingMemoryBound(to: Float32.self)
        let pcmBufferData = pcmBuffer.floatChannelData![0]
        memcpy(pcmBufferData, audioBufferData, Int(audioBuffer.mDataByteSize))

        return pcmBuffer
    }

    func testOldRms() throws {
        let result = AudioUtils.calculateRms(audioBuffer)
        XCTAssertEqual(result, 5.228129, "Result of Root Mean Square should be 5.228129")
    }

    func testNewRms() throws {
        let result = AudioUtils.newCalculateRms(audioBuffer)
        XCTAssertEqual(result, 5.228129, "Result of Root Mean Square should be 5.228129")
    }

    func testOldRmsPerformance() throws {
        self.measure {
            (0...1000000).forEach { _ in
                _ = AudioUtils.calculateRms(audioBuffer)
            }
        }
    }

    func testNewRmsPerformance() throws {
        self.measure {
            (0...1000000).forEach { _ in
                _ = AudioUtils.newCalculateRms(audioBuffer)
            }
        }
    }

    func testOldPerformFadeOut() {
        let length: Float32 = 6
        var data: [Float32] = [1, 1, 1, 1, 1, 1]
        let expected: [Float32] = [1.0, 0.8, 0.6, 0.4, 0.2, 0.0]

        data.withUnsafeMutableBufferPointer { bufferPointer in
            AudioUtils.oldPerformFade(true, length: length, data: bufferPointer.baseAddress)
        }

        let roundedData = data.map { round($0 * 10) / 10 }
        XCTAssertEqual(roundedData, expected, "Fade out did not produce the expected result")
    }

    func testOldPerformFadeIn() {
        let length: Float32 = 6
        var data: [Float32] = [1, 1, 1, 1, 1, 1]
        let expected: [Float32] = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

        data.withUnsafeMutableBufferPointer { bufferPointer in
            AudioUtils.oldPerformFade(false, length: length, data: bufferPointer.baseAddress)
        }

        let roundedData = data.map { round($0 * 10) / 10 }
        XCTAssertEqual(roundedData, expected, "Fade in did not produce the expected result")
    }

    func testNewPerformFadeOut() {
        let length: vDSP_Length = 6
        var data: [Float32] = [1, 1, 1, 1, 1, 1]
        let expected: [Float32] = [1.0, 0.8, 0.6, 0.4, 0.2, 0.0]

        data.withUnsafeMutableBufferPointer { bufferPointer in
            AudioUtils.newPerformFade(true, length: length, data: bufferPointer.baseAddress)
        }

        let roundedData = data.map { round($0 * 10) / 10 }
        XCTAssertEqual(roundedData, expected, "Fade out did not produce the expected result")
    }

    func testNewPerformFadeIn() {
        let length: vDSP_Length = 6
        var data: [Float32] = [1, 1, 1, 1, 1, 1]
        let expected: [Float32] = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

        data.withUnsafeMutableBufferPointer { bufferPointer in
            AudioUtils.newPerformFade(false, length: length, data: bufferPointer.baseAddress)
        }

        let roundedData = data.map { round($0 * 10) / 10 }
        XCTAssertEqual(roundedData, expected, "Fade in did not produce the expected result")
    }

    func testOldFadePerformance() throws {
        let audioBuffer = audioBufferToAVAudioPCMBuffer(audioBuffer: audioBuffer, format: bufferFormat)
        let buffer = BufferedAudio(audioBuffer: audioBuffer!, framePosition: AVAudioFramePosition(), shouldFadeOut: false, shouldFadeIn: true)
        let channelCount: UInt32 = 1
        self.measure {
            (0...1000000).forEach { _ in
                AudioUtils.oldFadeAudio(buffer, fadeOut: true, channelCount: channelCount)
            }
        }
    }

    func testNewFadePerformance() throws {
        let audioBuffer = audioBufferToAVAudioPCMBuffer(audioBuffer: audioBuffer, format: bufferFormat)
        let buffer = BufferedAudio(audioBuffer: audioBuffer!, framePosition: AVAudioFramePosition(), shouldFadeOut: false, shouldFadeIn: true)
        let channelCount: UInt32 = 1
        self.measure {
            (0...1000000).forEach { _ in
                AudioUtils.newFadeAudio(buffer, fadeOut: true, channelCount: channelCount)
            }
        }
    }

}
