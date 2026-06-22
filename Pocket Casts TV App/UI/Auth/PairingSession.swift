import SwiftUI
import PocketCastsServer

/// Drives the TV device-pairing flow: requests a device code, exposes the
/// pairing URL and user code for display (as text and QR), and polls until the
/// code is approved or fails. Shared by the sign-in and create-account screens.
@MainActor
@Observable
class PairingSession {
    enum State: Equatable {
        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.start, .start), (.error, .error), (.finished, .finished):
                return true
            default:
                return false
            }
        }
        case start
        case error(Error, String)
        case finished
    }

    private(set) var state: State = .start

    /// The user code split into individual characters for display.
    private(set) var codes: [String] = []

    /// The bare verification URL (e.g. `pocketcasts.com/pair`) shown as text.
    private(set) var pairURL: String?

    /// The verification URL with the code embedded, encoded into the QR code.
    private(set) var pairURLComplete: String?

    /// Requests a fresh device code and polls until it's approved, transparently
    /// requesting a new code if the current one expires before approval.
    func start() async {
        // Clear the previous attempt so a re-run doesn't show a stale QR/digits.
        codes = []
        pairURL = nil
        pairURLComplete = nil
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
            } catch is CancellationError {
                return
            } catch {
                tryAgain = false
                if !Task.isCancelled {
                    state = .error(error, error.localizedDescription)
                }
            }
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
}
