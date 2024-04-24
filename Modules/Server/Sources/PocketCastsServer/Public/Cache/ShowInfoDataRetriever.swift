import Foundation

/// Request information about an episode using the show notes endpoint
public actor ShowInfoDataRetriever {
    private var dataRequestMap: [String: Task<Data, Error>] = [:]

    public init() { }

    public func loadShowInfoData(
        for podcastUuid: String
    ) async throws -> Data {
        if let task = dataRequestMap[podcastUuid] {
            return try await task.value
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/show_notes/full/\(podcastUuid)")
        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        let task = Task<Data, Error> {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                dataRequestMap[podcastUuid] = nil
                return data
            } catch {
                dataRequestMap[podcastUuid] = nil
                throw error
            }
        }
        dataRequestMap[podcastUuid] = task

        return try await task.value
    }
}
