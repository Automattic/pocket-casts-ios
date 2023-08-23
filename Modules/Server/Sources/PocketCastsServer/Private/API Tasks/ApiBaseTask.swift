import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class ApiBaseTask: Operation {
    private let syncTimeout = 60 as TimeInterval
    private let isoDateFormatter = ISO8601DateFormatter()
    let apiVersion = "2"

    let dataManager: DataManager

    init(dataManager: DataManager = .sharedManager) {
        self.dataManager = dataManager
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
        } else if let token = TokenHelper.acquireToken() {
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
        var request = createRequest(url: requestUrl, method: "POST", token: token)
        do {
            request.httpBody = data

            let (responseData, response) = try URLConnection.sendSynchronousRequest(with: request)
            guard let httpResponse = response as? HTTPURLResponse else { return (nil, ServerConstants.HttpConstants.serverError) }
            if httpResponse.statusCode == ServerConstants.HttpConstants.unauthorized {
                if retryOnUnauthorized, let newToken = TokenHelper.acquireToken() {
                    return performPostToServer(url: url, token: newToken, data: data, retryOnUnauthorized: false)
                }

                // our token may have expired, remove it so next time a sync happens we'll acquire a new one
                KeychainHelper.removeKey(ServerConstants.Values.syncingV2TokenKey)
                return (nil, httpResponse.statusCode)
            }

            return (responseData, httpResponse.statusCode)
        } catch {
            FileLog.shared.addMessage("Failed to POST to server (\(url) \(error.localizedDescription)")
        }

        return (nil, ServerConstants.HttpConstants.serverError)
    }

    func getToServer(url: String, token: String, customHeaders: [String: String]? = nil) -> (Data?, HTTPURLResponse?) {
        return performGetToServer(url: url, token: token, customHeaders: customHeaders)
    }

    func performGetToServer(url: String, token: String, retryOnUnauthorized: Bool = true, customHeaders: [String: String]? = nil) -> (Data?, HTTPURLResponse?) {
        let requestUrl = ServerHelper.asUrl(url)
        var request = createRequest(url: requestUrl, method: "GET", token: token)
        if let customHeaders = customHeaders {
            for header in customHeaders {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }

        do {
            let (responseData, response) = try URLConnection.sendSynchronousRequest(with: request)
            guard let httpResponse = response as? HTTPURLResponse else { return (nil, nil) }
            if httpResponse.statusCode == ServerConstants.HttpConstants.unauthorized {
                if retryOnUnauthorized, let newToken = TokenHelper.acquireToken() {
                    return performGetToServer(url: url, token: newToken, retryOnUnauthorized: false, customHeaders: customHeaders)
                }

                // our token may have expired, remove it so next time a sync happens we'll acquire a new one
                KeychainHelper.removeKey(ServerConstants.Values.syncingV2TokenKey)
                return (nil, httpResponse)
            }

            return (responseData, httpResponse)
        } catch {
            FileLog.shared.addMessage("Failed to GET from server (\(url) \(error.localizedDescription)")
        }

        return (nil, nil)
    }

    func deleteToServer(url: String, token: String?, data: Data) -> (Data?, Int) {
        let url = ServerHelper.asUrl(url)
        var request = createRequest(url: url, method: "DELETE", token: token)
        do {
            request.httpBody = data

            let (responseData, response) = try URLConnection.sendSynchronousRequest(with: request)
            guard let httpResponse = response as? HTTPURLResponse else { return (nil, ServerConstants.HttpConstants.serverError) }
            if httpResponse.statusCode == ServerConstants.HttpConstants.unauthorized {
                // our token may have expired, remove it so next time a sync happens we'll acquire a new one
                KeychainHelper.removeKey(ServerConstants.Values.syncingV2TokenKey)
                return (nil, httpResponse.statusCode)
            }

            return (responseData, httpResponse.statusCode)
        } catch {
            FileLog.shared.addMessage("Failed to DELETE to server \(url.absoluteString) \(error.localizedDescription)")
        }

        return (nil, ServerConstants.HttpConstants.serverError)
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
}
