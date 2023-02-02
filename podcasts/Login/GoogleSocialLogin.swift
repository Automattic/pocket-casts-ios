import Foundation
import PocketCastsServer
import GoogleSignIn

enum GoogleSocialLoginError: Error {
    case emptyIdToken
}

class GoogleSocialLogin: SocialLogin {
    private weak var viewController: UIViewController?

    private var idToken = ""

    required init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func getToken() async throws {
        idToken = try await idToken(from: viewController!)
    }

    func login() async throws -> AuthenticationResponse {
        try await AuthenticationHelper.validateLogin(identityToken: idToken, provider: .google)
    }

    @MainActor
    private func idToken(from viewController: UIViewController) async throws -> String {
        try await withUnsafeThrowingContinuation { continuation in
            let config = GIDConfiguration(
                clientID: ApiCredentials.googleSignInSecret,
                serverClientID: ApiCredentials.googleSignInServerClientId
            )

            GIDSignIn.sharedInstance.signIn(with: config, presenting: viewController) { signInResult, error in
                if let error {

                    if let err = error as? GIDSignInError, err.code == .canceled {
                        continuation.resume(throwing: SocialLoginError.canceled)
                        return
                    }

                    continuation.resume(throwing: error)
                    return
                }

                guard let idToken = signInResult?.authentication.idToken else {
                    continuation.resume(throwing: GoogleSocialLoginError.emptyIdToken)
                    return
                }

                continuation.resume(returning: idToken)
            }
        }
    }
}
