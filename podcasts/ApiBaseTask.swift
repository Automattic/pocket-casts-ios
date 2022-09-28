import DataModel
import Foundation
import Utils

class ApiBaseTask: Operation {
    private let syncTimeout = 60 as TimeInterval
    private let isoDateFormatter = ISO8601DateFormatter()
    let apiVersion = "2"

    override func main() {
        autoreleasepool {
            runTaskSynchronously()
        }
    }

    func runTaskSynchronously() {
        if let token = KeychainHelper.string(for: Constants.Values.syncingV2TokenKey) {
            apiTokenAcquired(token: token)
        } else if let token = acquireSyncToken() {
            apiTokenAcquired(token: token)
        } else {
            apiTokenAcquisitionFailed()
        }
    }

    func postToServer(url: String, token: String?, data: Data) -> (Data?, Int) {
        let url = Server.asUrl(url)
        var request = createRequest(url: url, method: "POST", token: token)
        do {
            request.httpBody = data

            var response: URLResponse?
            let responseData = try SJURLConnection.sendSynchronousRequest(request, returning: &response)
            guard let httpResponse = response as? HTTPURLResponse else { return (nil, Server.HttpConstants.serverError) }
            if httpResponse.statusCode == Server.HttpConstants.unauthorized {
                // our token may have expired, remove it so next time a sync happens we'll acquire a new one
                KeychainHelper.removeKey(Constants.Values.syncingV2TokenKey)
                return (nil, httpResponse.statusCode)
            }

            return (responseData, httpResponse.statusCode)
        } catch {
            FileLog.shared.addMessage("Failed to post to server \(error.localizedDescription)")
        }

        return (nil, Server.HttpConstants.serverError)
    }

    func getToServer(url: String, token: String?, customHeaders: [String: String]? = nil) -> (Data?, HTTPURLResponse?) {
        let url = Server.asUrl(url)
        var request = createRequest(url: url, method: "GET", token: token)
        if let customHeaders = customHeaders {
            for header in customHeaders {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }

        do {
            var response: URLResponse?
            let responseData = try SJURLConnection.sendSynchronousRequest(request, returning: &response)
            guard let httpResponse = response as? HTTPURLResponse else { return (nil, nil) }
            if httpResponse.statusCode == Server.HttpConstants.unauthorized {
                // our token may have expired, remove it so next time a sync happens we'll acquire a new one
                KeychainHelper.removeKey(Constants.Values.syncingV2TokenKey)
                return (nil, httpResponse)
            }

            return (responseData, httpResponse)
        } catch {
            FileLog.shared.addMessage("Failed to post to server \(error.localizedDescription)")
        }

        return (nil, nil)
    }

    func deleteToServer(url: String, token: String?, data: Data) -> (Data?, Int) {
        let url = Server.asUrl(url)
        var request = createRequest(url: url, method: "DELETE", token: token)
        do {
            request.httpBody = data

            var response: URLResponse?
            let responseData = try SJURLConnection.sendSynchronousRequest(request, returning: &response)
            guard let httpResponse = response as? HTTPURLResponse else { return (nil, Server.HttpConstants.serverError) }
            if httpResponse.statusCode == Server.HttpConstants.unauthorized {
                // our token may have expired, remove it so next time a sync happens we'll acquire a new one
                KeychainHelper.removeKey(Constants.Values.syncingV2TokenKey)
                return (nil, httpResponse.statusCode)
            }

            return (responseData, httpResponse.statusCode)
        } catch {
            FileLog.shared.addMessage("Failed to post to server \(error.localizedDescription)")
        }

        return (nil, Server.HttpConstants.serverError)
    }

    func formatDate(_ date: Date?) -> String {
        if let date = date {
            return isoDateFormatter.string(from: date)
        }

        return ""
    }

    private func createRequest(url: URL, method: String, token: String?) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: syncTimeout)
        request.httpMethod = method
        request.addValue("application/octet-stream", forHTTPHeaderField: Server.HttpHeaders.accept)
        request.setValue("application/octet-stream", forHTTPHeaderField: Server.HttpHeaders.contentType)
        request.setValue(Constants.Values.privateUserAgent, forHTTPHeaderField: Server.HttpHeaders.userAgent)
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func acquireSyncToken() -> String? {
        var loginRequest = Api_UserLoginRequest()
        if let email = UserDefaults.standard.string(forKey: Constants.UserDefaults.syncingEmail) {
            loginRequest.email = email
        }
        if let password = KeychainHelper.string(for: Constants.Values.syncingPasswordKey) {
            loginRequest.password = password
        }
        loginRequest.scope = Constants.Values.apiScope

        let url = Server.Urls.api + "user/login"
        do {
            let data = try loginRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: nil, data: data)

            if let response = response, httpStatus == Server.HttpConstants.ok {
                let token = try Api_UserLoginResponse(serializedData: response).token
                KeychainHelper.save(string: token, key: Constants.Values.syncingV2TokenKey, accessibility: kSecAttrAccessibleAlways)

                return token
            }

            if httpStatus == Server.HttpConstants.unauthorized {
                FileLog.shared.addMessage("SyncTask logging user out, invalid password")
                SyncManager.signout()
            }
        } catch {
            FileLog.shared.addMessage("acquireSyncToken failed \(error.localizedDescription)")
        }

        return nil
    }

    // for subclasses that talk to the API server to override
    func apiTokenAcquired(token: String) {}
    func apiTokenAcquisitionFailed() { print("\(self) apiTokenAcquisitionFailed") }
}
