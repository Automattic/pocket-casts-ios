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
            if let storedToken = KeychainHelper.string(for: ServerConstants.Values.syncingV2TokenKey) {
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
        var refreshedRefreshToken: String? = nil
        var error: Error? = nil

        asyncAcquireToken { result in
            switch result {
            case .success(let authenticationResponse):
                refreshedToken = authenticationResponse?.token
                refreshedRefreshToken = authenticationResponse?.refreshToken
            case .failure(let resultError):
                refreshedToken = nil
                error = resultError
            }
            semaphore.signal()
        }

        semaphore.wait()

        if let token = refreshedToken, !token.isEmpty {
            ServerSettings.syncingV2Token = token
            ServerSettings.refreshToken = refreshedRefreshToken
        }
        else {
            // if the user doesn't have an email and password or SSO token, they aren't going to be able to acquire a sync token
            switch error as? APIError {
            case APIError.TOKEN_DEAUTH?, APIError.PERMISSION_DENIED?:
                tokenCleanUp()
            default:
                () // Do nothing so the user is not disrupted in the case of non-auth errors
            }

            return nil
        }

        return refreshedToken
    }

    // MARK: - Email / Password Token

    class func acquirePasswordToken() -> AuthenticationResponse? {
        guard let email = ServerSettings.syncingEmail(), let password = ServerSettings.syncingPassword() else {
            // if the user doesn't have an email and password, then we'll check if they're using SSO
            return nil
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login")
        do {
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.seconds)
            request.httpMethod = "POST"
            request.addValue("application/octet-stream", forHTTPHeaderField: ServerConstants.HttpHeaders.accept)
            request.setValue("application/octet-stream", forHTTPHeaderField: ServerConstants.HttpHeaders.contentType)
            if let privateUserAgent = ServerConfig.shared.syncDelegate?.privateUserAgent() {
                request.setValue(privateUserAgent, forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)
            }

            var loginRequest = Api_UserLoginRequest()
            loginRequest.email = email
            loginRequest.password = password
            loginRequest.scope = ServerConstants.Values.apiScope
            let data = try loginRequest.serializedData()
            request.httpBody = data

            let (responseData, response) = try URLConnection.sendSynchronousRequest(with: request)
            guard let validData = responseData, let httpResponse = response as? HTTPURLResponse else {
                FileLog.shared.addMessage("TokenHelper: Unable to acquire token")
                return nil
            }

            if httpResponse.statusCode == ServerConstants.HttpConstants.ok {
                let userLoginResponse = try Api_UserLoginResponse(serializedData: validData)
                return AuthenticationResponse(from: userLoginResponse)
            }

            if httpResponse.statusCode == ServerConstants.HttpConstants.unauthorized {
                FileLog.shared.addMessage("TokenHelper logging user out, invalid password")
                SyncManager.signout()
            }
        } catch {
            FileLog.shared.addMessage("TokenHelper acquireToken failed \(error.localizedDescription)")
        }

        return nil
    }


    // MARK: - Email / Password Token

    private class func asyncAcquireToken(completion: @escaping (Result<AuthenticationResponse?, Error>) -> Void) {
        if let authenticationResponse = acquirePasswordToken() {
            completion(.success(authenticationResponse))
            return
        }

        Task {
            do {
                let authenticationResponse = try await acquireIdentityToken()
                completion(.success(authenticationResponse))
            } catch let error {
                completion(.failure(error))
            }
        }
    }

    // MARK: - SSO Identity Token

    private class func acquireIdentityToken() async throws -> AuthenticationResponse {
        return try await ApiServerHandler.shared.refreshIdentityToken()
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

        if ServerSettings.refreshToken == nil {
            logMessages.append("no SSO token")
        }

        FileLog.shared.addMessage("Acquire Token was called, however the user has \(logMessages.joined(separator: ", ")).")
        FileLog.shared.addMessage("Sync account is in a weird state, logging user out")
        SyncManager.signout()
    }
}
