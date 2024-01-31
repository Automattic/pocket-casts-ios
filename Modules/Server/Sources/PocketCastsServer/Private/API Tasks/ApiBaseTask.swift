import Foundation
import PocketCastsDataModel
import PocketCastsUtils

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}

class ApiBaseTask: Operation {
    private let syncTimeout = 60 as TimeInterval
    private let isoDateFormatter = ISO8601DateFormatter()
    let apiVersion = "2"

    let dataManager: DataManager

    private let urlConnection: URLConnection
    private let tokenHelper: TokenHelper

    init(dataManager: DataManager = .sharedManager, urlConnection: URLConnection = URLConnection(handler: URLSession.shared)) {
        self.dataManager = dataManager
        self.urlConnection = urlConnection
        self.tokenHelper = TokenHelper(urlConnection: urlConnection)
        super.init()
    }

    override func main() {
        autoreleasepool {
            runTaskSynchronously()
        }
    }

    func runTaskSynchronously() {
        if let token = KeychainHelper.string(for: ServerConstants.Values.syncingV2TokenKey) {
            apiTokenAcquired(token: token)
        } else if let token = tokenHelper.acquireToken() {
            apiTokenAcquired(token: token)
        } else {
            apiTokenAcquisitionFailed()
        }
    }

    func postToServer(url: String, token: String, data: Data) -> (Data?, Int) {
        return performPostToServer(url: url, token: token, data: data)
    }

    private func performPostToServer(url: String, token: String, data: Data, retryOnUnauthorized: Bool = true) -> (Data?, Int) {
        let requestUrl = ServerHelper.asUrl(url)

        let (data, response) = requestToServer(url: requestUrl, method: .post, token: token, retryOnUnauthorized: retryOnUnauthorized, data: data)
        return (data, response?.statusCode ?? ServerConstants.HttpConstants.serverError)
    }

    func getToServer(url: String, token: String, customHeaders: [String: String]? = nil) -> (Data?, HTTPURLResponse?) {
        return performGetToServer(url: url, token: token, customHeaders: customHeaders)
    }

    func performGetToServer(url: String, token: String, retryOnUnauthorized: Bool = true, customHeaders: [String: String]? = nil) -> (Data?, HTTPURLResponse?) {
        let requestUrl = ServerHelper.asUrl(url)

        return requestToServer(url: requestUrl, method: .get, token: token, retryOnUnauthorized: retryOnUnauthorized, customHeaders: customHeaders)
    }

    func deleteToServer(url: String, token: String?, data: Data) -> (Data?, Int) {
        let url = ServerHelper.asUrl(url)

        let (data, response) =  requestToServer(url: url, method: .delete, token: token, data: data)
        return (data, response?.statusCode ?? ServerConstants.HttpConstants.serverError)
    }

    func requestToServer(url: URL, method: HTTPMethod, token: String?, retryOnUnauthorized: Bool = true, customHeaders: [String: String]? = nil, data: Data? = nil) -> (Data?, HTTPURLResponse?) {
        var request = createRequest(url: url, method: method.rawValue, token: token)

        if let customHeaders = customHeaders {
            for header in customHeaders {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }

        do {
            request.httpBody = data

            let (responseData, response) = try urlConnection.sendSynchronousRequest(with: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return (nil, HTTPURLResponse(url: url, statusCode: ServerConstants.HttpConstants.serverError, httpVersion: nil, headerFields: nil))
            }

            if httpResponse.statusCode == ServerConstants.HttpConstants.unauthorized {

                if retryOnUnauthorized, let newToken = tokenHelper.acquireToken() {
                    return requestToServer(url: url, method: method, token: newToken, retryOnUnauthorized: retryOnUnauthorized, customHeaders: customHeaders, data: data)
                }

                // our token may have expired, remove it so next time a sync happens we'll acquire a new one
                KeychainHelper.removeKey(ServerConstants.Values.syncingV2TokenKey)
                return (nil, httpResponse)
            }

            return (responseData, httpResponse)
        } catch {
            logFailure(method: method.rawValue, url: url.absoluteString, error: error)
        }

        return (nil, HTTPURLResponse(url: url, statusCode: ServerConstants.HttpConstants.serverError, httpVersion: nil, headerFields: nil))
    }

    func formatDate(_ date: Date?) -> String {
        if let date = date {
            return isoDateFormatter.string(from: date)
        }

        return ""
    }

    func createRequest(url: URL, method: String, token: String?) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: syncTimeout)
        request.httpMethod = method
        request.addValue("application/octet-stream", forHTTPHeaderField: ServerConstants.HttpHeaders.accept)
        request.setValue("application/octet-stream", forHTTPHeaderField: ServerConstants.HttpHeaders.contentType)
        let privateUserAgent = ServerConfig.shared.syncDelegate?.privateUserAgent() ?? ""
        request.setValue(privateUserAgent, forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // for subclasses that talk to the API server to override
    func apiTokenAcquired(token: String) {}
    func apiTokenAcquisitionFailed() { print("\(self) apiTokenAcquisitionFailed") }

    private func logFailure(method: String, url: String, error: Error) {
        FileLog.shared.addMessage("[\(type(of: self))] Failed to \(method) to server (\(url)) \(error)")
    }
}
