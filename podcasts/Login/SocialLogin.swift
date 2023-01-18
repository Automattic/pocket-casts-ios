import Foundation
import PocketCastsServer

protocol SocialLogin {
    init(viewController: UIViewController)

    /// This is the step in which an identification token is retrieved from the provider
    func getToken()

    /// Once the identification token is retrieved, this step is responsible to sending this to
    /// the server so the user identity may be verified
    func login() async throws -> AuthenticationResponse
}
