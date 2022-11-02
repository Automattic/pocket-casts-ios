import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
#if !os(watchOS)
import AuthenticationServices
#endif

class AuthenticationHelper {

    @discardableResult
    static func refreshLogin(scope: AuthenticationScope = .mobile) async throws -> String? {
        if let username = ServerSettings.syncingEmail(), let password = ServerSettings.syncingPassword(), !password.isEmpty {
            return try await validateLogin(username: username, password: password, scope: scope).token
        }
        else if FeatureFlag.signInWithApple, let token = ServerSettings.appleAuthIdentityToken, let userID = ServerSettings.appleAuthUserID {
            return try await validateLogin(identityToken: token, userID: userID).token
        }

        return nil
    }

    // MARK: Password

    static func validateLogin(username: String, password: String, scope: AuthenticationScope) async throws -> AuthenticationResponse {
        let response = try await ApiServerHandler.shared.validateLogin(username: username, password: password, scope: scope.rawValue)
        handleSuccessfulSignIn(response, .password)

        // If the server didn't return a new email, and the call was successful, then reset the email to the one used to
        // validate the login
        if ServerSettings.syncingEmail() == nil {
            ServerSettings.setSyncingEmail(email: username)
        }

        ServerSettings.saveSyncingPassword(password)

        return response
    }

    // MARK: Apple SSO

    static func validateLogin(identityToken: String, userID: String)  async throws -> AuthenticationResponse {
        let response = try await ApiServerHandler.shared.validateLogin(identityToken: identityToken)
        handleSuccessfulSignIn(response, .ssoApple)

        ServerSettings.appleAuthIdentityToken = identityToken
        ServerSettings.appleAuthUserID = userID

        return response
    }

    // MARK: Common

    private static func handleSuccessfulSignIn(_ response: AuthenticationResponse, _ source: AuthenticationSource) {
        SyncManager.clearTokensFromKeyChain()

        ServerSettings.userId = response.uuid
        ServerSettings.syncingV2Token = response.token

        // we've signed in, set all our existing podcasts to be non synced
        DataManager.sharedManager.markAllPodcastsUnsynced()

        ServerSettings.clearLastSyncTime()

        // This check may not be necessary in the long run see: https://github.com/Automattic/pocket-casts-ios/issues/412
        if let email = response.email, !email.isEmpty {
            ServerSettings.setSyncingEmail(email: response.email)
        }

        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)
        Analytics.track(.userSignedIn, properties: ["source": source])

        RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        Settings.setPromotionFinishedAcknowledged(true)
        Settings.setLoginDetailsUpdated()
    }
}

// MARK: - Only available to the main app, not the watch app
#if !os(watchOS)
extension AuthenticationHelper {
    static func validateLogin(appleIDCredential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = appleIDCredential.identityToken,
              let token = String(data: identityToken, encoding: .utf8)
        else {
            FileLog.shared.addMessage("Unable to parse Apple SSO token")
            throw APIError.UNKNOWN
        }

        try await validateLogin(identityToken: token, userID: appleIDCredential.user)
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
        Settings.setLoginDetailsUpdated()
    }
}
#endif

// MARK: - Enums
enum AuthenticationSource: String, AnalyticsDescribable {
    case password = "password"
    case ssoApple = "sso_apple"

    var analyticsDescription: String { rawValue }
}

enum AuthenticationScope: String {
    case mobile
    case sonos
}
