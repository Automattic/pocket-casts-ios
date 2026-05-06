import SwiftUI
import Combine
import PocketCastsServer

@Observable
class SignInViewModel {
    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case waiting
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

    func manualSignIn(username: String, password: String) {
        ApiServerHandler.shared.validateLogin(username: username, password: password) { success, userId, error in
            print("Success: \(success), userId: \(userId ?? "") error: \(error)")
        }
    }
}
