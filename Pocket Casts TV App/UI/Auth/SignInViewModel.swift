import SwiftUI
import Combine
import PocketCastsServer

@MainActor
@Observable
class SignInViewModel {
    private var cancellable: AnyCancellable?

    enum State: Equatable {
        static func == (lhs: SignInViewModel.State, rhs: SignInViewModel.State) -> Bool {
            switch (lhs, rhs) {
            case (.start, .start):
                return true
            case (.waiting, .waiting):
                return true
            case (.finished, .finished):
                return true
            case (.error, .error):
                return true
            default:
                return false
            }
        }
        case start
        case waiting
        case error(Error, String)
        case finished
    }

    var state: State = .start

    var codes: [String] = []

    var pairURL: String?

    var pairURLComplete: String?

    func thirdPartyApprovalSignin() async {
        codes = []
        state = .start

        var tryAgain = true
        while tryAgain {
            if Task.isCancelled { return }
            do {
                let authorizeResponse = try await AuthenticationHelper.deviceAuthorizeCode()
                codes = authorizeResponse.userCode.map({ char in
                    String(char)
                })
                pairURL = authorizeResponse.verificationURI
                pairURLComplete = authorizeResponse.verificationURIComplete

                try await AuthenticationHelper.deviceWaitForApproval(deviceCode: authorizeResponse.deviceCode)
                state = .finished
            } catch let error as APIError {
                if case APIError.EXPIRED_TOKEN = error {
                    tryAgain = true
                } else {
                    tryAgain = false
                    if !Task.isCancelled {
                        state = .error(error, error.localizedDescription)
                    }
                }
            } catch {
                tryAgain = false
                if !Task.isCancelled {
                    state = .error(error, error.localizedDescription)
                }
            }
        }
    }

    func manualSignIn(username: String, password: String) async {
        state = .waiting
        do {
            let response = try await AuthenticationHelper.validateLogin(username: username, password: password, scope: .mobile)
            if response.token != nil {
                state = .finished
            }
        } catch let error as APIError {
            state = .error(error, error.localizedDescription)
        } catch {
            state = .error(error, "Please try again")
        }
    }

    var pairURLPretty: String {
        guard let url = URL(string: pairURL ?? ServerConstants.Urls.tvPair),
             let host = url.host()
        else {
            return ServerConstants.Urls.tvPair
        }
        return host + url.path()
    }

    var pairURLString: String {
        return pairURLComplete ?? ServerConstants.Urls.tvPair
    }
}
