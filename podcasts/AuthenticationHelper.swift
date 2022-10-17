import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import AuthenticationServices

enum AuthenticationSource: String {
    case password = "password"
    case ssoApple = "sso_apple"
}


extension AuthenticationResponse {
    // TODO: Determine what signifies a new account vs login
    var accountCreated: Bool {
        return true
    }
}

class AuthenticationHelper {
    enum Result {
        case accountCreated
        case loggedIn
    }

    static func validateLogin(_ appleIDCredential: ASAuthorizationAppleIDCredential) async throws -> Result {
        let response = try await ApiServerHandler.shared.validateLogin(identityToken: appleIDCredential.identityToken)
        handleSuccessfulSignIn(response, .ssoApple)
        if let identityToken = appleIDCredential.identityToken {
            ServerSettings.appleAuthIdentityToken = String(data: identityToken, encoding: .utf8)
            ServerSettings.appleAuthUserID = appleIDCredential.user
        }

        return response.accountCreated ? .accountCreated : .loggedIn
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

    private static func handleSuccessfulSignIn(_ response: AuthenticationResponse, _ source: AuthenticationSource) {
        SyncManager.clearTokensFromKeyChain()

        ServerSettings.userId = response.uuid
        ServerSettings.syncingV2Token = response.token

        // we've signed in, set all our existing podcasts to be non synced
        DataManager.sharedManager.markAllPodcastsUnsynced()

        ServerSettings.clearLastSyncTime()
        ServerSettings.setSyncingEmail(email: response.email)

        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)

        if response.accountCreated {
            Analytics.track(.userAccountCreated, properties: ["source": source.rawValue])
        } else {
            Analytics.track(.userSignedIn, properties: ["source": source.rawValue])
        }

        RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        Settings.setPromotionFinishedAcknowledged(true)
        Settings.setLoginDetailsUpdated()
    }
}
