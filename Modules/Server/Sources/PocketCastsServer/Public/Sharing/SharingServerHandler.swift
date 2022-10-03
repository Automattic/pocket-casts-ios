import Foundation

public class SharingServerHandler {
    private static let timeout: TimeInterval = 20

    public static let shared = SharingServerHandler()

    public struct PodcastShareInfo: Codable {
        public let title: String
        public let description: String?
        public let podcasts: [String]

        public init(title: String, description: String, podcasts: [String]) {
            self.title = title
            self.description = description
            self.podcasts = podcasts
        }
    }

    public struct PodcastList: Decodable {
        public let title: String?
        public let listDescription: String?
        public let podcasts: [ListPodcast]?

        public enum CodingKeys: String, CodingKey {
            case title, podcasts
            case listDescription = "description"
        }
    }

    public struct ListPodcast: Decodable {
        public let title: String?
        public let uuid: String?
        public let podcastDescription: String?
        public let author: String?
        public let iTunesId: Int?

        public enum CodingKeys: String, CodingKey {
            case title, uuid, author
            case podcastDescription = "description"
            case iTunesId = "collection_id"
        }
    }

    private lazy var securityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"

        return formatter
    }()

    private struct PodcastShareRequest: Codable {
        let title: String
        let description: String?
        let podcasts: [[String: String]]

        var datetime: String?
        var h: String?
    }

    private struct PodcastShareResponse: Decodable {
        var status: String?
        var result: PodcastShareResult?
    }

    private struct PodcastShareResult: Decodable {
        var shareUrl: String?

        enum CodingKeys: String, CodingKey {
            case shareUrl = "share_url"
        }
    }

    public func sharePodcastList(listInfo: PodcastShareInfo, completion: @escaping (_ shareUrl: String?) -> Void) {
        let url = ServerHelper.asUrl(ServerConstants.Urls.sharing() + "share/list")

        let convertedPodcasts = listInfo.podcasts.compactMap { uuid -> [String: String] in
            ["uuid": uuid]
        }
        var shareRequest = PodcastShareRequest(title: listInfo.title, description: listInfo.description, podcasts: convertedPodcasts)

        // add security params
        let dateStr = securityDateFormatter.string(from: Date())
        shareRequest.datetime = dateStr
        shareRequest.h = "\(dateStr)\(ServerCredentials.sharing)".insecureSHA1Hash()

        guard let request = ServerHelper.createJsonRequest(url: url, params: shareRequest, timeout: SharingServerHandler.timeout, cachePolicy: .useProtocolCachePolicy) else {
            completion(nil)

            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard (response as? HTTPURLResponse)?.statusCode == ServerConstants.HttpConstants.ok, let data = data, error == nil else {
                completion(nil)

                return
            }

            do {
                let shareUrl = try JSONDecoder().decode(PodcastShareResponse.self, from: data).result?.shareUrl
                completion(shareUrl)
            } catch {
                completion(nil)
            }
        }.resume()
    }

    public func loadList(listUrl: URL, completion: @escaping (_ podcastList: PodcastList?) -> Void) {
        URLSession.shared.dataTask(with: listUrl) { data, response, error in
            guard (response as? HTTPURLResponse)?.statusCode == ServerConstants.HttpConstants.ok, let data = data, error == nil else {
                completion(nil)

                return
            }

            do {
                let podcastList = try JSONDecoder().decode(PodcastList.self, from: data)
                completion(podcastList)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
