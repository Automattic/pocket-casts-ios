import XCTest

@testable import podcasts

final class FingerprintGeneratorTests: XCTestCase {

    private var tempFileURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let data = Data((0..<1024).map { UInt8($0 % 256) })
        tempFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FingerprintGeneratorTests-\(UUID().uuidString).bin")
        try data.write(to: tempFileURL)
    }

    override func tearDownWithError() throws {
        if let tempFileURL, FileManager.default.fileExists(atPath: tempFileURL.path) {
            try? FileManager.default.removeItem(at: tempFileURL)
        }
        tempFileURL = nil
        try super.tearDownWithError()
    }

    // MARK: - Full-file generation

    func testGenerateWithValidFileReturnsFingerprint() {
        let fingerprinter = MockFingerprinter(result: .success(.stub))
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)

        let result = waitForResult { completion in
            generator.generate(for: tempFileURL, completion: completion)
        }

        guard case let .success(fingerprint) = result else {
            return XCTFail("Expected success, got \(result)")
        }
        XCTAssertEqual(fingerprint.format, ReferenceFingerprint.supportedFormat)
        XCTAssertEqual(fingerprinter.receivedDataSize, 1024)
    }

    func testGenerateWithMissingFileFailsWithFileNotFound() {
        let fingerprinter = MockFingerprinter(result: .success(.stub))
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("does-not-exist-\(UUID().uuidString).bin")

        let result = waitForResult { completion in
            generator.generate(for: missingURL, completion: completion)
        }

        guard case .failure(.fileNotFound) = result else {
            return XCTFail("Expected .fileNotFound, got \(result)")
        }
    }

    func testGenerateWithNonFileURLFailsWithFileNotFound() {
        let fingerprinter = MockFingerprinter(result: .success(.stub))
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)
        let httpURL = URL(string: "https://example.com/audio.mp3")!

        let result = waitForResult { completion in
            generator.generate(for: httpURL, completion: completion)
        }

        guard case .failure(.fileNotFound) = result else {
            return XCTFail("Expected .fileNotFound, got \(result)")
        }
    }

    // MARK: - Byte range validation

    func testGenerateWithValidByteRangeSlicesFile() {
        let fingerprinter = MockFingerprinter(result: .success(.stub))
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)

        let result = waitForResult { completion in
            generator.generate(for: tempFileURL, byteRange: 100..<200, completion: completion)
        }

        guard case .success = result else {
            return XCTFail("Expected success, got \(result)")
        }
        XCTAssertEqual(fingerprinter.receivedDataSize, 100)
    }

    func testGenerateWithOutOfBoundsRangeFailsWithInvalidByteRange() {
        let fingerprinter = MockFingerprinter(result: .success(.stub))
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)

        let result = waitForResult { completion in
            generator.generate(for: tempFileURL, byteRange: 0..<2048, completion: completion)
        }

        guard case .failure(.invalidByteRange) = result else {
            return XCTFail("Expected .invalidByteRange, got \(result)")
        }
    }

    func testGenerateWithEmptyRangeFailsWithInvalidByteRange() {
        let fingerprinter = MockFingerprinter(result: .success(.stub))
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)

        let result = waitForResult { completion in
            generator.generate(for: tempFileURL, byteRange: 50..<50, completion: completion)
        }

        guard case .failure(.invalidByteRange) = result else {
            return XCTFail("Expected .invalidByteRange, got \(result)")
        }
    }

    func testGenerateWithOverflowingUpperBoundFailsWithInvalidByteRange() {
        let fingerprinter = MockFingerprinter(result: .success(.stub))
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)

        let result = waitForResult { completion in
            generator.generate(
                for: tempFileURL,
                byteRange: 0..<UInt64(Int.max) + 1,
                completion: completion
            )
        }

        guard case .failure(.invalidByteRange) = result else {
            return XCTFail("Expected .invalidByteRange, got \(result)")
        }
    }

    // MARK: - Cancellation

    func testCancellationBeforeStartReturnsCancelled() {
        let fingerprinter = MockFingerprinter(result: .success(.stub))
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)
        let token = FingerprintCancellationToken()
        token.cancel()

        let result = waitForResult { completion in
            generator.generate(for: tempFileURL, cancellationToken: token, completion: completion)
        }

        guard case .failure(.cancelled) = result else {
            return XCTFail("Expected .cancelled, got \(result)")
        }
        XCTAssertFalse(fingerprinter.wasCalled, "Fingerprinter should not run after cancellation")
    }

    func testCancellationMidProgressStopsProgressCallbacks() {
        let token = FingerprintCancellationToken()
        let fingerprinter = MockFingerprinter(
            result: .success(.stub),
            progressValues: [0.25, 0.5, 0.75, 1.0],
            onProgress: { value in
                if value >= 0.5 {
                    token.cancel()
                }
            }
        )
        let generator = FingerprintGenerator(fingerprinter: fingerprinter)

        var observedProgress: [Double] = []
        _ = waitForResult { completion in
            generator.generate(
                for: tempFileURL,
                cancellationToken: token,
                progress: { observedProgress.append($0) },
                completion: completion
            )
        }

        XCTAssertTrue(observedProgress.allSatisfy { $0 < 0.75 },
                      "Progress callbacks after cancellation should be suppressed, got \(observedProgress)")
    }
}

// MARK: - Helpers

private extension FingerprintGeneratorTests {
    func waitForResult(
        timeout: TimeInterval = 2,
        _ invoke: (@escaping FingerprintGenerator.CompletionHandler) -> Void
    ) -> Result<ReferenceFingerprint, FingerprintGenerator.GenerationError> {
        let expectation = expectation(description: "generation completed")
        var captured: Result<ReferenceFingerprint, FingerprintGenerator.GenerationError>!
        invoke { result in
            captured = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        return captured
    }
}

private final class MockFingerprinter: AudioFingerprinting {
    private let result: Result<ReferenceFingerprint, Error>
    private let progressValues: [Double]
    private let onProgress: ((Double) -> Void)?
    private(set) var receivedDataSize: Int = 0
    private(set) var wasCalled = false

    init(
        result: Result<ReferenceFingerprint, Error>,
        progressValues: [Double] = [],
        onProgress: ((Double) -> Void)? = nil
    ) {
        self.result = result
        self.progressValues = progressValues
        self.onProgress = onProgress
    }

    func generateReferenceFingerprint(
        from audioData: Data,
        progress: ((Double) -> Void)?
    ) throws -> ReferenceFingerprint {
        wasCalled = true
        receivedDataSize = audioData.count
        for value in progressValues {
            onProgress?(value)
            progress?(value)
        }
        switch result {
        case .success(let fingerprint):
            return fingerprint
        case .failure(let error):
            throw error
        }
    }
}

private extension ReferenceFingerprint {
    static var stub: ReferenceFingerprint {
        ReferenceFingerprint(
            format: ReferenceFingerprint.supportedFormat,
            totalDuration: 60,
            checkpointInterval: 1,
            checkpointDuration: 1,
            topK: 4,
            timestampQuantum: 1,
            checkpoints: []
        )
    }
}
