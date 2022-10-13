import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import AuthenticationServices

public extension ApiServerHandler {
    func validateLogin(identityToken: Data?, completion: @escaping (Result<AuthenticationResponse, APIError>) -> Void) {
        guard let identityToken = identityToken,
              let token = String(data: identityToken, encoding: .utf8),
              let request = tokenRequest(identityToken: token)
        else {
            FileLog.shared.addMessage("Unable to create protobuffer request to obtain token via Apple SSO")
            completion(.failure(.UNKNOWN))
            return
        }

        obtainToken(request: request, completion: completion)
    }

    func refreshIdentityToken(completion: @escaping (Result<String?, APIError>) -> Void) {
        Task {
            do {
                let token = try await refreshIdentityToken()
                completion(.success(token))
            } catch {
                completion(.failure((error as? APIError) ?? .UNKNOWN))
            }
        }
    }

    func refreshIdentityToken() async throws -> String? {
        guard
            let identityToken = ServerSettings.appleAuthIdentityToken,
            let request = tokenRequest(identityToken: identityToken, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.seconds)
        else {
            FileLog.shared.addMessage("Unable to locate Apple SSO token in Keychain")
            throw APIError.UNKNOWN
        }

        if try await hasValidSSOToken() {
            let response = try await obtainToken(request: request)
            return response.token
        } else {
            return nil
        }
    }

    func ssoCredentialState() async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        guard let userID = ServerSettings.appleAuthUserID else { return .notFound }
        return try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
    }

    func hasValidSSOToken() async throws -> Bool {
        let tokenState = try await ssoCredentialState()

        switch tokenState {
        case .authorized:
            return true
        default:
            FileLog.shared.addMessage("Apple SSO token has been revoked")
            return false
        }
    }

    private func tokenRequest(identityToken: String?, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 15.seconds) -> URLRequest? {
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login_apple")
        guard let identityToken = identityToken,
              var request = ServerHelper.createEmptyProtoRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        else { return nil }

        request.setValue("Bearer \(identityToken)", forHTTPHeaderField: ServerConstants.HttpHeaders.authorization)
        return request
    }
}
