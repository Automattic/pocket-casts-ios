import Foundation
import PocketCastsDataModel
import PocketCastsServer
import AuthenticationServices

class AuthenticationHelper {
    static func processAppleIDCredential(_ appleIDCredential: ASAuthorizationAppleIDCredential, _ completion: @escaping (Result<Bool, Error>) -> Void) {
        ApiServerHandler.shared.validateLogin(identityToken: appleIDCredential.identityToken) { result in
            switch result {
            case .success(let response):
                handleSuccessfulSignIn(response)
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private static func handleSuccessfulSignIn(_ response: AuthenticationResponse) {
        SyncManager.clearTokensFromKeyChain()

        ServerSettings.userId = response.uuid
        ServerSettings.syncingV2Token = response.token

        // we've signed in, set all our existing podcasts to be non synced
        DataManager.sharedManager.markAllPodcastsUnsynced()

        ServerSettings.clearLastSyncTime()
        ServerSettings.setSyncingEmail(email: response.email)

        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)
        // TODO: Track login source details
//        Analytics.track(.userSignedIn)

        RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        Settings.setPromotionFinishedAcknowledged(true)
        Settings.setLoginDetailsUpdated()
    }
}
