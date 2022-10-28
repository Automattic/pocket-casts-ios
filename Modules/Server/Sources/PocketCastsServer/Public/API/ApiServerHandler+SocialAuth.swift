import Foundation
import PocketCastsDataModel
import PocketCastsUtils

/**
 * The Watch app and the iOS app don't share SIWA credentials, so if we try to do an "Credentials State" check from SIWA
 * from the watch, it will fail regardless. So, instead we will rely on the server to validate the identity token and fail
 * there if needed.
 *
 * We will still do the credential state check in the main app, since it's better to fail early if possible.
 *
 */
#if !os(watchOS)
import AuthenticationServices

public extension ASAuthorizationAppleIDProvider.CredentialState {
    var loggingValue: String {
        switch self {
        case .revoked:
            return "revoked (\(rawValue))"
        case .authorized:
            return "authorized (\(rawValue))"
        case .notFound:
            return "notFound (\(rawValue))"
        case .transferred:
            return "transferred (\(rawValue))"
        default:
            return "unknown raw value: \(rawValue)}"
        }
    }
}
#endif

public extension ApiServerHandler {
    func validateLogin(identityToken: String?) async throws -> AuthenticationResponse {
        guard let identityToken = identityToken,
              let request = tokenRequest(identityToken: identityToken)
        else {
            FileLog.shared.addMessage("Unable to create protobuffer request to obtain token via Apple SSO")
            throw APIError.UNKNOWN
        }

        return try await obtainToken(request: request)
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

    private func tokenRequest(identityToken: String?, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 15.seconds) -> URLRequest? {
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login_apple")
        guard let identityToken = identityToken,
              var request = ServerHelper.createEmptyProtoRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        else { return nil }

        request.setValue("Bearer \(identityToken)", forHTTPHeaderField: ServerConstants.HttpHeaders.authorization)
        return request
    }
}

// MARK: - Only available to the main app, not the watch app
#if !os(watchOS)
extension ApiServerHandler {
    public func ssoCredentialState() async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        guard let userID = ServerSettings.appleAuthUserID else { return .notFound }
        return try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
    }

    private func hasValidSSOToken() async throws -> Bool {
        let tokenState = try await ssoCredentialState()
        FileLog.shared.addMessage("Validated Apple SSO token state: \(tokenState.loggingValue)")

        switch tokenState {
        case .authorized:
            return true
        default:
            FileLog.shared.addMessage("Apple SSO token has been revoked")
            return false
        }
    }
}
#else

extension ApiServerHandler {
    func hasValidSSOToken() async throws -> Bool {
        return true
    }
}
#endif
