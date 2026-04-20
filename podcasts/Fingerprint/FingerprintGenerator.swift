import Foundation
import PocketCastsUtils

// MARK: - AudioFingerprinting

protocol AudioFingerprinting {
    func generateReferenceFingerprint(
        from audioData: Data,
        progress: ((Double) -> Void)?
    ) throws -> ReferenceFingerprint
}

// MARK: - FingerprintCancellationToken

final class FingerprintCancellationToken {
    private let lock = NSLock()
    private var _isCancelled = false

    var isCancelled: Bool {
        lock.withLock { _isCancelled }
    }

    func cancel() {
        lock.withLock { _isCancelled = true }
    }
}

// MARK: - FingerprintGenerator

final class FingerprintGenerator {

    enum GenerationError: Error {
        case fileNotFound(URL)
        case invalidByteRange
        case cancelled
        case generationFailed(Error)
    }

    typealias ProgressHandler = (Double) -> Void
    typealias CompletionHandler = (Result<ReferenceFingerprint, GenerationError>) -> Void

    private let fingerprinter: AudioFingerprinting
    private let queue = DispatchQueue(
        label: "com.pocketcasts.fingerprint.generation",
        qos: .utility
    )

    init(fingerprinter: AudioFingerprinting) {
        self.fingerprinter = fingerprinter
    }

    func generate(
        for fileURL: URL,
        cancellationToken: FingerprintCancellationToken? = nil,
        progress: ProgressHandler? = nil,
        completion: @escaping CompletionHandler
    ) {
        queue.async { [self] in
            completion(performGeneration(
                fileURL: fileURL,
                byteRange: nil,
                cancellationToken: cancellationToken,
                progress: progress
            ))
        }
    }

    func generate(
        for fileURL: URL,
        byteRange: Range<UInt64>,
        cancellationToken: FingerprintCancellationToken? = nil,
        progress: ProgressHandler? = nil,
        completion: @escaping CompletionHandler
    ) {
        queue.async { [self] in
            completion(performGeneration(
                fileURL: fileURL,
                byteRange: byteRange,
                cancellationToken: cancellationToken,
                progress: progress
            ))
        }
    }

    // MARK: - Private

    private func performGeneration(
        fileURL: URL,
        byteRange: Range<UInt64>?,
        cancellationToken: FingerprintCancellationToken?,
        progress: ProgressHandler?
    ) -> Result<ReferenceFingerprint, GenerationError> {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            FileLog.shared.addMessage("FingerprintGenerator: file not found at \(fileURL.path)")
            return .failure(.fileNotFound(fileURL))
        }

        if cancellationToken?.isCancelled == true {
            return .failure(.cancelled)
        }

        let audioData: Data
        do {
            let fileData = try Data(contentsOf: fileURL, options: .mappedIfSafe)

            if let byteRange {
                let lower = Int(byteRange.lowerBound)
                let upper = Int(byteRange.upperBound)
                guard lower < fileData.count, upper <= fileData.count else {
                    FileLog.shared.addMessage(
                        "FingerprintGenerator: byte range \(lower)..<\(upper) out of bounds for file of size \(fileData.count)"
                    )
                    return .failure(.invalidByteRange)
                }
                audioData = fileData[lower..<upper]
            } else {
                audioData = fileData
            }
        } catch {
            FileLog.shared.addMessage("FingerprintGenerator: failed to read file — \(error.localizedDescription)")
            return .failure(.generationFailed(error))
        }

        if cancellationToken?.isCancelled == true {
            return .failure(.cancelled)
        }

        do {
            let fingerprint = try fingerprinter.generateReferenceFingerprint(
                from: audioData,
                progress: { value in
                    guard cancellationToken?.isCancelled != true else { return }
                    progress?(value)
                }
            )

            if cancellationToken?.isCancelled == true {
                return .failure(.cancelled)
            }

            FileLog.shared.addMessage(
                "FingerprintGenerator: generated fingerprint for \(fileURL.lastPathComponent) "
                    + "(\(fingerprint.checkpoints.count) checkpoints)"
            )
            return .success(fingerprint)
        } catch {
            if cancellationToken?.isCancelled == true {
                return .failure(.cancelled)
            }
            FileLog.shared.addMessage("FingerprintGenerator: generation failed — \(error.localizedDescription)")
            return .failure(.generationFailed(error))
        }
    }
}
