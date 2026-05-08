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

    var codes: [String] = ["J", "M", "R", "S", "3", "W"]

    func signinWait() {
        state = .waiting
        cancellable = Timer.publish(every: 5.0, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        guard let self else { return }
                        state = .finished
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
}
