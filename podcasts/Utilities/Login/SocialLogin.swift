import Foundation
import PocketCastsServer

enum SocialLoginError: Error {
    case canceled
}

protocol SocialLogin {
    init(viewController: UIViewController)

    /// This is the step in which an identification token is retrieved from the provider
    func getToken() async throws

    /// Once the identification token is retrieved, this step is responsible to sending this to
    /// the server so the user identity may be verified
    func login() async throws -> AuthenticationResponse
}
