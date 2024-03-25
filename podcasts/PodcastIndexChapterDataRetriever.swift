import Foundation

public struct PodcastIndexEvelope: Decodable {
    let chapters: [PodcastIndexChapter]
}

struct PodcastIndexChapter: Decodable {
    let title: String?
    let number: Int?
    let endTime: TimeInterval?
    let startTime: TimeInterval
}

/// Request information about an episode using the show notes endpoint
public actor PodcastIndexChapterDataRetriever {
    private let podcastIndexChaptersCache: URLCache

    private var dataRequestMap: [String: Task<PodcastIndexEvelope, Error>] = [:]

    public init() {
        podcastIndexChaptersCache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 10.megabytes, diskPath: "show_notes")
    }

    public func loadChapters(_ urlString: String) async throws -> PodcastIndexEvelope {
        if let task = dataRequestMap[urlString] {
            return try await task.value
        }

        guard let url = URL(string: urlString) else {
            throw Errors.malformedURL
        }

        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        if let cachedResponse = podcastIndexChaptersCache.cachedResponse(for: request) {
            return try chapters(from: cachedResponse.data)
        }

        let task = Task<PodcastIndexEvelope, Error> {
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseToCache = CachedURLResponse(response: response, data: data)
            podcastIndexChaptersCache.storeCachedResponse(responseToCache, for: request)
            dataRequestMap[urlString] = nil

            return try chapters(from: data)
        }

        dataRequestMap[urlString] = task

        return try await task.value
    }

    private func chapters(from data: Data) throws -> PodcastIndexEvelope {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PodcastIndexEvelope.self, from: data)
    }

    enum Errors: Error {
        case malformedURL
    }
}
