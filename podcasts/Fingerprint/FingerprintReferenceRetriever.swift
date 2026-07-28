import Compression
import Foundation
import PocketCastsServer
import PocketCastsUtils

actor FingerprintReferenceRetriever {

    static let shared = FingerprintReferenceRetriever()

    private var inFlightRequests: [String: Task<Data?, any Error>] = [:]
    private static let maxRetries = 3

    func fetchReferenceData(podcastUuid: String, episodeUuid: String) async -> Data? {
        let key = "\(podcastUuid)/\(episodeUuid)"

        if let existing = inFlightRequests[key] {
            return try? await existing.value
        }

        let task = Task<Data?, any Error> {
            try await performFetch(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        }

        inFlightRequests[key] = task
        defer { inFlightRequests[key] = nil }
        return await withTaskCancellationHandler {
            try? await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func performFetch(podcastUuid: String, episodeUuid: String) async throws -> Data? {
        let urlString = "\(ServerConstants.Urls.generatedTranscripts)\(podcastUuid)/\(episodeUuid)-fingerprints.json.gz"
        guard let url = URL(string: urlString) else {
            FileLog.shared.addMessage("FingerprintReferenceRetriever: invalid URL for \(episodeUuid)")
            return nil
        }

        for attempt in 0..<Self.maxRetries {
            try Task.checkCancellation()
            if attempt > 0 {
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                do {
                    try await Task.sleep(nanoseconds: delay)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    FileLog.shared.addMessage(
                        "FingerprintReferenceRetriever: retry delay failed for \(episodeUuid) — \(error.localizedDescription)"
                    )
                    return nil
                }
            }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let statusCode = response.extractStatusCode()

                if statusCode == ServerConstants.HttpConstants.notFound {
                    FileLog.shared.addMessage("FingerprintReferenceRetriever: no reference for \(episodeUuid) (404)")
                    return nil
                }

                guard statusCode == ServerConstants.HttpConstants.ok else {
                    if statusCode >= ServerConstants.HttpConstants.serverError {
                        FileLog.shared.addMessage(
                            "FingerprintReferenceRetriever: server error \(statusCode) for \(episodeUuid), "
                                + "attempt \(attempt + 1)/\(Self.maxRetries)"
                        )
                        continue
                    }
                    FileLog.shared.addMessage(
                        "FingerprintReferenceRetriever: unexpected status \(statusCode) for \(episodeUuid)"
                    )
                    return nil
                }

                guard let jsonData = Self.decompressGzipIfNeeded(data) else {
                    FileLog.shared.addMessage("FingerprintReferenceRetriever: decompression failed for \(episodeUuid)")
                    return nil
                }

                FileLog.shared.addMessage(
                    "FingerprintReferenceRetriever: reference fetched for \(episodeUuid) (\(jsonData.count) bytes)"
                )
                return jsonData
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                if Self.isTransientError(error) {
                    FileLog.shared.addMessage(
                        "FingerprintReferenceRetriever: transient error for \(episodeUuid), "
                            + "attempt \(attempt + 1)/\(Self.maxRetries) — \(error.localizedDescription)"
                    )
                    continue
                }
                FileLog.shared.addMessage(
                    "FingerprintReferenceRetriever: fetch failed for \(episodeUuid) — \(error.localizedDescription)"
                )
                return nil
            }
        }

        FileLog.shared.addMessage("FingerprintReferenceRetriever: exhausted retries for \(episodeUuid)")
        return nil
    }

    // MARK: - Gzip Decompression

    static func decompressGzipIfNeeded(_ data: Data) -> Data? {
        guard data.count >= 2 else { return data }

        if data[data.startIndex] == 0x1f, data[data.startIndex + 1] == 0x8b {
            return decompressGzip(data)
        }

        return data
    }

    private static func decompressGzip(_ data: Data) -> Data? {
        guard data.count >= 10 else { return nil }

        var offset = 10
        let flags = data[data.startIndex + 3]

        if flags & 0x04 != 0 {
            guard data.count > offset + 2 else { return nil }
            let extraLen = Int(data[data.startIndex + offset])
                | (Int(data[data.startIndex + offset + 1]) << 8)
            offset += 2 + extraLen
        }
        if flags & 0x08 != 0 {
            while offset < data.count, data[data.startIndex + offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x10 != 0 {
            while offset < data.count, data[data.startIndex + offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x02 != 0 { offset += 2 }

        guard data.count > offset + 8 else { return nil }

        let isizeOffset = data.startIndex + data.count - 4
        let isize = Int(data[isizeOffset])
            | (Int(data[isizeOffset + 1]) << 8)
            | (Int(data[isizeOffset + 2]) << 16)
            | (Int(data[isizeOffset + 3]) << 24)

        let compressedSlice = data[(data.startIndex + offset)..<(data.startIndex + data.count - 8)]
        let bufferSize = min(max(isize, compressedSlice.count * 4), 50_000_000)
        guard bufferSize > 0 else { return nil }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        let decompressedSize = compressedSlice.withUnsafeBytes { rawBuffer -> Int in
            guard let baseAddress = rawBuffer.baseAddress else { return 0 }
            return compression_decode_buffer(
                buffer,
                bufferSize,
                baseAddress.assumingMemoryBound(to: UInt8.self),
                compressedSlice.count,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard decompressedSize > 0 else { return nil }
        return Data(bytes: buffer, count: decompressedSize)
    }

    private static func isTransientError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        return [
            NSURLErrorTimedOut,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorCannotConnectToHost,
        ].contains(nsError.code)
    }
}
