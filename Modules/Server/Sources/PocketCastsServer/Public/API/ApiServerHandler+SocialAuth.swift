import Foundation
import PocketCastsDataModel
import PocketCastsUtils

/**
 * The Watch app and the iOS app don't share SIWA credentials, so if we try to do an "Credentials State" check from SIWA
 * from the watch, it will fail regardless. So, instead we will rely on the server to validate the identity token and fail there if needed. If not, then the watch will check the login state next time the user is connected to the main app on their phone.
 *
 * We will still do the credential state check in the main app since it's recommended by Apple.
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

    func validateLogin(identityToken: String, provider: SocialAuthProvider) async throws -> AuthenticationResponse {
        guard let request = tokenRequest(identityToken: identityToken, provider: provider)
        else {
            FileLog.shared.addMessage("Unable to create protobuffer request to obtain token via SSO")
            throw APIError.UNKNOWN
        }

        return try await obtainToken(request: request)
    }

    func refreshIdentityToken() async throws -> AuthenticationResponse {
        guard
            let identityToken = ServerSettings.refreshToken,
            let request = tokenRequest(identityToken: identityToken, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.seconds)
        else {
            FileLog.shared.addMessage("Unable to locate Apple SSO token in Keychain")
            throw APIError.UNKNOWN
        }

        return try await obtainToken(request: request)
    }

    private func tokenRequest(identityToken: String?, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 15.seconds) -> URLRequest? {
        guard let identityToken else {
            return nil
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/token")

        var data = Api_UserTokenRequest()
        data.refreshToken = identityToken
        data.grantType = "refresh_token"

        var request = ServerHelper.createProtoRequest(url: url, data: try! data.serializedData())
        request?.setValue("Bearer \(ServerSettings.syncingV2Token!)", forHTTPHeaderField: ServerConstants.HttpHeaders.authorization)
        return request

    }

    private func tokenRequest(identityToken: String?, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 15.seconds, provider: SocialAuthProvider) -> URLRequest? {
        guard let identityToken else {
            return nil
        }

        var data = Api_TokenLoginRequest()
        data.idToken = identityToken

        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + provider.endpointURL)

        return ServerHelper.createProtoRequest(url: url, data: try! data.serializedData())
    }
}

public enum SocialAuthProvider {
    case apple
    case google

    var endpointURL: String {
        switch self {
        case .apple:
            return "user/login_apple"
        case .google:
            return "user/login_google"
        }
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
    private func hasValidSSOToken() async throws -> Bool {
        return true
    }
}
#endif
