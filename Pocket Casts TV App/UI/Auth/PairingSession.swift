import SwiftUI
import PocketCastsServer

/// Drives the TV device-pairing flow used to authenticate a viewer from their
/// phone: it requests a device code, exposes the pairing URL and user code for
/// display (as text and as a QR code), and polls until the code is approved or
/// the attempt fails.
///
/// The sign-in and create-account screens share an identical flow, so both own
/// a `PairingSession` rather than duplicating the polling logic.
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

    /// Requests a fresh device code and polls until it's approved. If the code
    /// expires before approval it transparently requests a new one and keeps
    /// polling, so the screen can stay open indefinitely.
    func start() async {
        // Clear the previous attempt's code so a re-run (e.g. "Try Again", or a
        // reused session) doesn't briefly show a stale QR / digits while the new
        // device code is being fetched.
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

    var pairURLString: String {
        return pairURLComplete ?? ServerConstants.Urls.tvPair
    }
}
