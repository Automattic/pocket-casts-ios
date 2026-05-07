import SwiftUI
import Combine
import PocketCastsServer

@MainActor
@Observable
class SignInViewModel {
    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case waiting
        case error
        case finished
    }

    var state: State = .waiting

    var codes: [String] = ["J", "M", "R", "S", "3", "W"]

    func signinWait() {
        cancellable = Timer.publish(every: 5.0, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        guard let self else { return }
                        state = .finished
                    }
    }

    func manualSignIn(username: String, password: String) async {
        do {
            let response = try await AuthenticationHelper.validateLogin(username: username, password: password, scope: .mobile)
            if response.token != nil {
                state = .finished
            }
        } catch let apiError as APIError {
            state = .error
        } catch {
            state = .error
        }
    }
}
