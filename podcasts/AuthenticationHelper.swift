import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import AuthenticationServices

enum AuthenticationSource: String {
    case password = "password"
    case ssoApple = "sso_apple"
}

enum AuthenticationScope: String {
    case mobile
    case sonos
}

class AuthenticationHelper {

    @discardableResult
    static func refreshLogin(scope: AuthenticationScope = .mobile) async throws -> String? {
        if let username = ServerSettings.syncingEmail(), let password = ServerSettings.syncingPassword(), !password.isEmpty {
            return try await validateLogin(username: username, password: password, scope: scope).token
        }
        else if FeatureFlag.signInWithApple, let token = ServerSettings.appleAuthIdentityToken {
            return try await validateLogin(identityToken: token).token
        }

        return nil
    }

    // MARK: Password

    static func validateLogin(username: String, password: String, scope: AuthenticationScope) async throws -> AuthenticationResponse {
        let response = try await ApiServerHandler.shared.validateLogin(username: username, password: password, scope: scope.rawValue)
        handleSuccessfulSignIn(response, .password)
        ServerSettings.saveSyncingPassword(password)

        return response
    }

    // MARK: Apple SSO

    static func validateLogin(appleIDCredential: ASAuthorizationAppleIDCredential) async throws -> AuthenticationResponse {
        guard let identityToken = appleIDCredential.identityToken,
              let token = String(data: identityToken, encoding: .utf8)
        else {
            FileLog.shared.addMessage("Unable to parse Apple SSO token")
            throw APIError.UNKNOWN
        }

        let response = try await validateLogin(identityToken: token)

        ServerSettings.appleAuthIdentityToken = String(data: identityToken, encoding: .utf8)
        ServerSettings.appleAuthUserID = appleIDCredential.user

        return response
    }

    static func validateLogin(identityToken: String) async throws -> AuthenticationResponse {
        let response = try await ApiServerHandler.shared.validateLogin(identityToken: identityToken)
        handleSuccessfulSignIn(response, .ssoApple)
        return response
    }

    static func validateAppleSSOCredentials() {
        guard ServerSettings.appleAuthUserID != nil else {
            // No need to Check if we don't have a user ID
            return
        }
        Task {
            let state = try await ApiServerHandler.shared.ssoCredentialState()
            FileLog.shared.addMessage("Validated Apple SSO token state: \(state.loggingValue)")
            switch state {
            case .revoked, .transferred:
                handleSSOTokenRevoked()
            default:
                break
            }
        }
    }

    static func observeAppleSSOEvents() {
        NotificationCenter.default.addObserver(forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification, object: nil, queue: .main) { _ in
            handleSSOTokenRevoked()
        }
    }

    private static func handleSSOTokenRevoked() {
        FileLog.shared.addMessage("Apple SSO token has been revoked. Signing user out.")
        SyncManager.signout()
    }

    // MARK: Common

    private static func handleSuccessfulSignIn(_ response: AuthenticationResponse, _ source: AuthenticationSource) {
        SyncManager.clearTokensFromKeyChain()

        ServerSettings.userId = response.uuid
        ServerSettings.syncingV2Token = response.token

        // we've signed in, set all our existing podcasts to be non synced
        DataManager.sharedManager.markAllPodcastsUnsynced()

        ServerSettings.clearLastSyncTime()
        ServerSettings.setSyncingEmail(email: response.email)

        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)
        Analytics.track(.userSignedIn, properties: ["source": source.rawValue])

        RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        Settings.setPromotionFinishedAcknowledged(true)
        Settings.setLoginDetailsUpdated()
    }
}
