import XCTest
@testable import podcasts

class AudioReadTaskTests: XCTestCase {
    var audioReadTask: AudioReadTask!
    var mockAudioFile: MockAVAudioFile!
    var mockOutputFormat: AVAudioFormat!
    var mockBufferManager: PlayBufferManager!

    override func setUp() {
        super.setUp()
        mockOutputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        mockAudioFile = MockAVAudioFile(format: mockOutputFormat, duration: 10*60*60)
        mockBufferManager = PlayBufferManager()
//        mockBufferManager = MockPlayBufferManager()
        audioReadTask = AudioReadTask(trimSilence: .off,
                                      audioFile: mockAudioFile,
                                      outputFormat: mockOutputFormat,
                                      bufferManager: mockBufferManager,
                                      playPositionHint: 0,
                                      frameCount: 44100) // 1 second of audio
    }

    override func tearDown() {
        audioReadTask.shutdown()
        audioReadTask = nil
        mockAudioFile = nil
        mockOutputFormat = nil
        mockBufferManager = nil
        super.tearDown()
    }

    func testConcurrentSeekOperations() {
        let expectation = XCTestExpectation(description: "Concurrent seek operations")
        expectation.expectedFulfillmentCount = 100

        for _ in 0..<100 {
            DispatchQueue.global().async {
                self.audioReadTask.seekTo(Double.random(in: 0...1)) { _ in
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testRapidStartupShutdown() {
        let expectation = XCTestExpectation(description: "Rapid startup/shutdown")
        expectation.expectedFulfillmentCount = 100

        for _ in 0..<100 {
            DispatchQueue.global().async {
                self.audioReadTask.startup()
                self.audioReadTask.shutdown()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testEndOfFileSemaphoreStress() {
        let expectation = XCTestExpectation(description: "End of file semaphore stress")

        // Simulate reaching end of file multiple times
        DispatchQueue.global().async {
            for _ in 0..<1000 {
                self.mockAudioFile.simulateEndOfFile()
                self.audioReadTask.seekTo(0) { _ in }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func testBufferSemaphoreStress() {
        let bufferManager = self.mockBufferManager! // Capture the buffer manager
        let expectation = XCTestExpectation(description: "Buffer semaphore stress")

        // Start the audio read task
        audioReadTask.startup()

        // Simulate rapid buffer fills and empties
        DispatchQueue.global().async {
            for _ in 0..<1000 {
                // Simulate some processing time
                Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.005))
                self.audioReadTask.seekTo(Double.random(in: 0...10*60)) { _ in }

                // Simulate buffer full with a timeout
//                bufferManager.bufferSemaphore.wait()
//                bufferManager.simulateBufferFull()

                // Simulate some more processing time
//                Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.005))

                // Simulate buffer empty
//                bufferManager.bufferSemaphore.signal()
//                bufferManager.simulateBufferEmpty()

                // If we timed out waiting for the buffer to be full, it might indicate a problem
//                if !fullResult {
//                    print("Warning: Timed out waiting for buffer to be full")
//                }
            }
            expectation.fulfill()
        }

        // Wait for the test to complete
        wait(for: [expectation], timeout: 120.0)

        // Verify that no read errors occurred
        XCTAssertFalse(bufferManager.readErrorOccurred.value, "Read error occurred during stress test")
    }



    func testConcurrentOperations() {
        let seekExpectation = XCTestExpectation(description: "Concurrent seek operations")
        let bufferExpectation = XCTestExpectation(description: "Concurrent buffer operations")
        let trimSilenceExpectation = XCTestExpectation(description: "Concurrent trim silence changes")

        audioReadTask.startup()

        DispatchQueue.global().async {
            for _ in 0..<100 {
                self.audioReadTask.seekTo(Double.random(in: 0...1)) { _ in }
            }
            seekExpectation.fulfill()
        }

        DispatchQueue.global().async {
            for _ in 0..<100 {
                self.mockBufferManager.bufferSemaphore.wait()
                self.mockBufferManager.bufferSemaphore.signal()
//                self.mockBufferManager.simulateBufferFull()
//                self.mockBufferManager.simulateBufferEmpty()
            }
            bufferExpectation.fulfill()
        }

        DispatchQueue.global().async {
            for _ in 0..<100 {
                self.audioReadTask.setTrimSilence(.off)
                self.audioReadTask.setTrimSilence(.low)
                self.audioReadTask.setTrimSilence(.medium)
                self.audioReadTask.setTrimSilence(.high)
            }
            trimSilenceExpectation.fulfill()
        }

        wait(for: [seekExpectation, bufferExpectation, trimSilenceExpectation], timeout: 30.0)
    }

    func testCallOrdering() {
        let bufferManager = self.mockBufferManager! // Capture the buffer manager
        let expectation = XCTestExpectation(description: "Buffer semaphore stress")

        // Start the audio read task
        audioReadTask.startup()

        // Simulate rapid buffer fills and empties
        DispatchQueue.global().async {
            for _ in 0..<1000 {
                // Simulate some processing time
                Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.005))
                self.audioReadTask.seekTo(Double.random(in: 0...10*60)) { _ in }

                // Simulate buffer full with a timeout
//                bufferManager.bufferSemaphore.wait()
//                bufferManager.simulateBufferFull()

                // Simulate some more processing time
//                Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.005))

                // Simulate buffer empty
//                bufferManager.bufferSemaphore.signal()
//                bufferManager.simulateBufferEmpty()

                // If we timed out waiting for the buffer to be full, it might indicate a problem
//                if !fullResult {
//                    print("Warning: Timed out waiting for buffer to be full")
//                }
            }
            expectation.fulfill()
        }

        // Wait for the test to complete
        wait(for: [expectation], timeout: 120.0)

        // Verify that no read errors occurred
        XCTAssertFalse(bufferManager.readErrorOccurred.value, "Read error occurred during stress test")
    }
}

class MockAVAudioFile: AVAudioFile {
    private let audioFormat: AVAudioFormat
    private let totalFrames: AVAudioFramePosition
    private(set) var currentFrame: AVAudioFramePosition = 0

    init(format: AVAudioFormat, duration: TimeInterval) {
        self.audioFormat = format
        self.totalFrames = AVAudioFramePosition(duration * format.sampleRate)
        super.init()
    }

    override var fileFormat: AVAudioFormat {
        return audioFormat
    }

    override var length: AVAudioFramePosition {
        return totalFrames
    }

    override var framePosition: AVAudioFramePosition {
        get { return currentFrame }
        set { currentFrame = max(0, min(newValue, totalFrames)) }
    }

    override func read(into buffer: AVAudioPCMBuffer) throws {
        guard currentFrame < totalFrames else {
            //TODO: Throw error
            return
        }

        let framesToRead = min(AVAudioFrameCount(totalFrames - currentFrame), buffer.frameCapacity)
        buffer.frameLength = framesToRead

        // Fill the buffer with dummy data (silence)
        for i in 0..<Int(audioFormat.channelCount) {
            if let channelData = buffer.floatChannelData?[i] {
                for j in 0..<Int(framesToRead) {
                    channelData[j] = 0.0
                }
            }
        }

        currentFrame += AVAudioFramePosition(framesToRead)
        return
    }

    func simulateEndOfFile() {
        currentFrame = totalFrames
    }
}

class MockPlayBufferManager: PlayBufferManager {
    func simulateBufferFull() {
        bufferSemaphore.wait()
    }

    func simulateBufferEmpty() {
        bufferSemaphore.signal()
    }
}
