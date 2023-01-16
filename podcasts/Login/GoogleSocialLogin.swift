import Foundation
import GoogleSignIn

class GoogleSocialLogin {
    func getToken(from viewController: UIViewController) {
        let config = GIDConfiguration(
            clientID: ApiCredentials.googleSignInSecret,
            serverClientID: ApiCredentials.googleSignInServerClientId
        )

        GIDSignIn.sharedInstance.signIn(with: config, presenting: viewController) { [weak self] signInResult, error in
            guard error == nil else { return }

            guard let idToken = signInResult?.authentication.idToken else {
                return
            }

            self?.handleGoogleCredential(idToken)
        }
    }

    func handleGoogleCredential(_ idToken: String) {
        Task {
            var success = false
            do {
                try await AuthenticationHelper.validateLogin(identityToken: idToken, provider: .google)
                success = true
            } catch {
                DispatchQueue.main.async {
//                    self.showError(error)
                }
            }

            if success {
                DispatchQueue.main.async {
    //                    self.signingProcessCompleted()
                }
            }

        }
    }
}
