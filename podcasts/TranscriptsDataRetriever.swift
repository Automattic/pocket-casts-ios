import Foundation
import PocketCastsUtils
import PocketCastsServer

actor TranscriptsDataRetriever {

    private var dataRequestMap: [URL: Task<Data, Error>] = [:]

    private let cache: URLCache

    public init() {
        cache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 100.megabytes, diskPath: "transcripts")
    }

    public func loadTranscript(url: URL) async throws -> String? {
        let request = URLRequest(url: url)

        if let cachedResponse = cache.cachedResponse(for: request),
           let result = String(data: cachedResponse.data, encoding: .utf8),
           !result.trim().isEmpty {
            FileLog.shared.addMessage("Transcripts Data Retriever: returning cached data for transcript")
            Task {
                // trigger a background refresh to force cache update
                try? await loadTranscriptFromServer(url, previousResponse: cachedResponse)
            }
            return result
        }

        return try await loadTranscriptFromServer(url)
    }

    private func loadTranscriptFromServer(_ url: URL, previousResponse: CachedURLResponse? = nil) async throws -> String? {
        if let task = dataRequestMap[url] {
            return try await String(data: task.value, encoding: .utf8)
        }
        FileLog.shared.addMessage("Transcripts Data Retriever: requesting transcript data \(url)")

        let task = Task<Data, Error> {
            do {
                var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                if let previousResponse {
                    request.setRefreshHeadersUsing(cachedResponse: previousResponse)
                }
                let (data, response) = try await urlSession.data(for: request)
                defer {
                    dataRequestMap[url] = nil
                }

                guard response.extractStatusCode() == 200 else {
                    FileLog.shared.addMessage("Transcripts Data Retriever: request failed for transcript url \(url).")
                    return data
                }

                let responseToCache = CachedURLResponse(response: response, data: data)
                cache.storeCachedResponse(responseToCache, for: request)
                FileLog.shared.addMessage("Transcripts Data Retriever: request succeeded for url \(url).")

                return data
            } catch {
                FileLog.shared.addMessage("Transcripts Data Retriever: request failed for url \(url): \(error.localizedDescription).")
                dataRequestMap[url] = nil
                throw error
            }
        }
        dataRequestMap[url] = task

        return try await String(data: task.value, encoding: .utf8)
    }

    private lazy var urlSession: URLSession = {
        return URLSession(configuration: .ephemeral)
    }()
}
