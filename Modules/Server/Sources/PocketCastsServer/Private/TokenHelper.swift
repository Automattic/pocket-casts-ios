import Foundation
import PocketCastsUtils

class TokenHelper {
    class func callSecureUrl(request: URLRequest, completion: @escaping ((HTTPURLResponse?, Data?, Error?) -> Void)) {
        DispatchQueue.global().async {
            performCallSecureUrl(request: request, retryOnUnauthorized: true, completion: completion)
        }
    }

    private class func performCallSecureUrl(request: URLRequest, retryOnUnauthorized: Bool = true, completion: @escaping ((HTTPURLResponse?, Data?, Error?) -> Void)) {
        var mutableRequest = request

        if let privateUserAgent = ServerConfig.shared.syncDelegate?.privateUserAgent() {
            mutableRequest.setValue(privateUserAgent, forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)
        }

        if SyncManager.isUserLoggedIn() {
            let token: String
            if let storedToken = ServerSettings.syncingV2Token {
                token = storedToken
            } else if let newToken = TokenHelper.acquireToken() {
                token = newToken
            } else {
                completion(nil, nil, nil)
                return
            }

            mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: ServerConstants.HttpHeaders.authorization)
        }

        URLSession.shared.dataTask(with: mutableRequest) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, nil, error)
                return
            }

            if httpResponse.statusCode == ServerConstants.HttpConstants.unauthorized {
                if SyncManager.isUserLoggedIn(), retryOnUnauthorized {
                    KeychainHelper.removeKey(ServerConstants.Values.syncingV2TokenKey)
                    performCallSecureUrl(request: request, retryOnUnauthorized: false, completion: completion)
                } else {
                    completion(httpResponse, nil, error)
                }

                return
            }

            completion(httpResponse, data, error)
        }.resume()
    }

    class func acquireToken() -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        var refreshedToken: String? = nil

        asyncAcquireToken { result in
            switch result {
            case .success(let token):
                refreshedToken = token
            case .failure:
                refreshedToken = nil
            }
            semaphore.signal()
        }

        semaphore.wait()

        if let token = refreshedToken, !token.isEmpty {
            ServerSettings.syncingV2Token = token
        }
        else {
            // if the user doesn't have an email and password or SSO token, they aren't going to be able to acquire a sync token
            tokenCleanUp()
            return nil
        }

        return refreshedToken
    }

    private class func asyncAcquireToken(completion: @escaping (Result<String?, APIError>) -> Void) {
        Task {
            if async let token = await acquirePasswordToken() ?? await acquireIdentityToken() {
                completion(.success(token))
            }
            else {
                completion(.failure(.UNKNOWN))
            }
        }
    }


    // MARK: - Email / Password Token

    class func acquirePasswordToken() async -> String? {
        guard let email = ServerSettings.syncingEmail(), let password = ServerSettings.syncingPassword(), !password.isEmpty else {
            // if the user doesn't have an email and password, then we'll check if they're using SSO
            return nil
        }

        do {
            return try await ApiServerHandler.shared.validateLogin(username: email, password: password, scope: ServerConstants.Values.apiScope)
        }
        catch {
            FileLog.shared.addMessage("TokenHelper Password acquireToken failed \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - SSO Identity Token

    private class func acquireIdentityToken() async -> String? {
        do {
            return try await ApiServerHandler.shared.refreshIdentityToken()
        }
        catch {
            FileLog.shared.addMessage("TokenHelper SSO acquireToken failed \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: Cleanup

    private class func tokenCleanUp() {
        var logMessages = [String]()
        if ServerSettings.syncingEmail() == nil {
            logMessages.append("no email address")
        }

        if ServerSettings.syncingPassword() == nil {
            logMessages.append("no password")
        }

        if ServerSettings.appleAuthIdentityToken == nil {
            logMessages.append("no SSO token")
        }

        FileLog.shared.addMessage("Acquire Token was called, however the user has \(logMessages.joined(separator: ", ")).")
        FileLog.shared.addMessage("Sync account is in a weird state, logging user out")
        SyncManager.signout()
    }
}
