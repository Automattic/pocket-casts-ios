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

    var codes: [String] = ["X", "X", "X", "X", "X", "X"]

    func signinWait() async {
        do {
            let code = try await AuthenticationHelper.deviceAuthorizeCode()
            codes = code.components(separatedBy: "")
        } catch {
            state = .error(error, error.localizedDescription)
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
        guard let url = URL(string: ServerConstants.Urls.tvPair),
             let host = url.host()
        else {
            return ServerConstants.Urls.tvPair
        }
        return host + url.path()
    }

    var pairURLString: String {
        return ServerConstants.Urls.tvPair
    }
}
