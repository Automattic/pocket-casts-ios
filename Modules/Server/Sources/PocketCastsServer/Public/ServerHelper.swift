import Foundation
import PocketCastsUtils

public class ServerHelper: NSObject {
    // MARK: Url Helpers

    public static func asUrl(_ url: String) -> URL {
        URL(string: url)!
    }

    public static func image(podcastUuid: String, size: Int) -> String {
        "\(ServerConstants.Urls.discover())images/\(size)/\(podcastUuid).jpg"
    }

    public static func imageUrl(podcastUuid: String, size: Int) -> URL {
        let location = "\(ServerConstants.Urls.discover())images/\(size)/\(podcastUuid).jpg"

        return URL(string: location)!
    }

    public static func userEpisodeDefaultImageUrl(isDark: Bool, color: Int, size: Int) -> URL {
        let themeType = isDark ? "dark" : "light"
        let location = "\(ServerConstants.Urls.discover())images/artwork/\(themeType)/\(size)/\(color).png"

        return URL(string: location)!
    }

    public static func colorUrl(podcastUuid: String) -> URL {
        URL(string: "\(ServerConstants.Urls.discover())images/metadata/\(podcastUuid).json")!
    }

    public static func playerUrl(podcastUuid: String, episodeUuid: String, playedUpTo: Double) -> URL {
        let urlString = NSString(format: "https://play.pocketcasts.com/web/user/handoff?podcast=%@&episode=%@&t=%1.0lf", podcastUuid, episodeUuid, round(playedUpTo))

        return URL(string: urlString as String)!
    }

    public static func bundleUrl(bundleUuid: String) -> URL {
        URL(string: "\(ServerConstants.Urls.lists())bundle-\(bundleUuid).json")!
    }

    class func decodeRefreshResponse(from data: Data) -> PodcastRefreshResponse {
        do {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            return try jsonDecoder.decode(PodcastRefreshResponse.self, from: data)
        } catch {
            FileLog.shared.addMessage("Unable to decode refresh response \(error.localizedDescription)")
            return PodcastRefreshResponse.failedResponse()
        }
    }

    class func createJsonRequest(url: URL, data: Data, timeout: TimeInterval, cachePolicy: URLRequest.CachePolicy) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: ServerConstants.HttpHeaders.accept)
        request.setValue("application/json; charset=UTF8", forHTTPHeaderField: ServerConstants.HttpHeaders.contentType)
        request.setValue(ServerConfig.shared.syncDelegate?.privateUserAgent(), forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)
        request.httpBody = data

        return request
    }

    class func createJsonRequest<T: Encodable>(url: URL, params: T, timeout: TimeInterval, cachePolicy: URLRequest.CachePolicy) -> URLRequest? {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: ServerConstants.HttpHeaders.accept)
        request.setValue("application/json; charset=UTF8", forHTTPHeaderField: ServerConstants.HttpHeaders.contentType)
        request.setValue(ServerConfig.shared.syncDelegate?.privateUserAgent(), forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)

        do {
            let dataToSend = try JSONEncoder().encode(params)
            request.httpBody = dataToSend
        } catch {
            FileLog.shared.addMessage("Encoding JSON request failed \(error.localizedDescription)")
            return nil
        }

        return request
    }

    class func createProtoRequest(url: URL, data: Data) -> URLRequest? {
        var request = createEmptyProtoRequest(url: url)
        request?.httpBody = data

        return request
    }

    class func createEmptyProtoRequest(url: URL, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 15.seconds) -> URLRequest? {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.addValue("application/octet-stream", forHTTPHeaderField: ServerConstants.HttpHeaders.accept)
        request.setValue("application/octet-stream", forHTTPHeaderField: ServerConstants.HttpHeaders.contentType)
        request.setValue(ServerConfig.shared.syncDelegate?.privateUserAgent(), forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)

        return request
    }
}
