import Foundation
import GoogleSignIn

enum GoogleSocialLoginError: Error {
    case emptyIdToken
}

class GoogleSocialLogin {
    func getToken(from viewController: UIViewController) async throws -> Bool {
        let idToken = try await idToken(from: viewController)

        try await AuthenticationHelper.validateLogin(identityToken: idToken, provider: .google)

        return true
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
