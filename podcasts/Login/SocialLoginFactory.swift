import Foundation
import PocketCastsServer

class SocialLoginFactory {
    static func provider(for provider: SocialAuthProvider, from viewController: UIViewController) -> SocialLogin {
        switch provider {
        case .apple:
            return AppleSocialLogin(viewController: viewController)
        case .google:
            return GoogleSocialLogin(viewController: viewController)
        }
    }
}
