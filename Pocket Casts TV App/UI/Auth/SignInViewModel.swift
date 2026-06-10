import SwiftUI
import PocketCastsServer

@MainActor
@Observable
class SignInViewModel {
    /// The QR / device-pairing flow, shared with the create-account screen.
    let pairing = PairingSession()

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

    /// State of the manual username / password sign-in.
    var state: State = .start

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
