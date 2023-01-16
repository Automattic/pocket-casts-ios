import Foundation
import GoogleSignIn

class GoogleSocialLogin {
    func getToken(from viewController: UIViewController) {
        let config = GIDConfiguration(
            clientID: ApiCredentials.googleSignInSecret,
            serverClientID: ApiCredentials.googleSignInServerClientId
        )

        GIDSignIn.sharedInstance.signIn(with: config, presenting: viewController) { signInResult, error in
            guard error == nil else { return }

            guard let idToken = signInResult?.authentication.idToken else {
                return
            }

            print(idToken)
          }
    }
}
