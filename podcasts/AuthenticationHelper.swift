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
        else if let token = ServerSettings.refreshToken {
            return try await validateLogin(identityToken: token, scope: scope).token
        }

        return nil
    }

    // MARK: Password

    static func validateLogin(username: String, password: String, scope: AuthenticationScope) async throws -> AuthenticationResponse {
        let response = try await ApiServerHandler.shared.validateLogin(username: username, password: password, scope: scope.rawValue)
        handleSuccessfulSignIn(response)

        // If the server didn't return a new email, and the call was successful, then reset the email to the one used to
        // validate the login
        if ServerSettings.syncingEmail() == nil {
            ServerSettings.setSyncingEmail(email: username)
        }

        ServerSettings.saveSyncingPassword(password)

        return response
    }

    // MARK: Apple SSO

    static func validateLogin(identityToken: String, scope: AuthenticationScope = .mobile)  async throws -> AuthenticationResponse {
        let response = try await ApiServerHandler.shared.validateLogin(identityToken: identityToken, scope: scope)
        handleSuccessfulSignIn(response)

        ServerSettings.refreshToken = response.refreshToken

        return response
    }

    static func validateLogin(identityToken: String, provider: SocialAuthProvider)  async throws -> AuthenticationResponse {
        let response = try await ApiServerHandler.shared.validateLogin(identityToken: identityToken, provider: provider)
        handleSuccessfulSignIn(response)

        return response
    }

    // MARK: Common

    private static func handleSuccessfulSignIn(_ response: AuthenticationResponse) {
        SyncManager.clearTokensFromKeyChain()

        ServerSettings.userId = response.uuid
        ServerSettings.syncingV2Token = response.token
        ServerSettings.refreshToken = response.refreshToken

        // we've signed in, set all our existing podcasts to
        // be non synced if the user never logged in before
        if (FeatureFlag.onlyMarkPodcastsUnsyncedForNewUsers.enabled && ServerSettings.lastSyncTime == nil)
            || !FeatureFlag.onlyMarkPodcastsUnsyncedForNewUsers.enabled {
            DataManager.sharedManager.markAllPodcastsUnsynced()
        }

        SyncManager.syncReason = .login
        ServerSettings.clearLastSyncTime()

        // This check may not be necessary in the long run see: https://github.com/Automattic/pocket-casts-ios/issues/412
        if let email = response.email, !email.isEmpty {
            ServerSettings.setSyncingEmail(email: response.email)
        }

        NotificationCenter.postOnMainThread(notification: .userLoginDidChange)

        RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        Settings.setPromotionFinishedAcknowledged(true)
        Settings.setLoginDetailsUpdated()
    }
}
