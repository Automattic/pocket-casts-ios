import Foundation
import AuthenticationServices
import PocketCastsServer

enum AppleSocialLoginError: Error {
    case emptyIdToken
}

class AppleSocialLogin: NSObject, SocialLogin {
    private weak var viewController: UIViewController?

    private var idToken = ""

    private var continuation: UnsafeContinuation<String, Error>?

    required init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func getToken() async throws {
        idToken = try await idToken(from: viewController!)
    }

    func login() async throws -> AuthenticationResponse {
        try await AuthenticationHelper.validateLogin(identityToken: idToken, provider: .apple)
    }

    @MainActor
    private func idToken(from viewController: UIViewController) async throws -> String {
        try await withUnsafeThrowingContinuation { continuation in
            self.continuation = continuation

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
}

// MARK: - Sign In With Apple

extension AppleSocialLogin: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = viewController?.view.window else { return SceneHelper.mainWindow! }
        return window
    }
}

extension AppleSocialLogin: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            if let identityTokenData = appleIDCredential.identityToken,
               let identityToken = String(data: identityTokenData, encoding: .utf8) {
                continuation?.resume(returning: identityToken)
            } else {
                continuation?.resume(throwing: AppleSocialLoginError.emptyIdToken)
            }
        default:
            break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let err = error as? ASAuthorizationError, err.code == .canceled {
            continuation?.resume(throwing: SocialLoginError.canceled)
            return
        }

        continuation?.resume(throwing: error)
    }
}
