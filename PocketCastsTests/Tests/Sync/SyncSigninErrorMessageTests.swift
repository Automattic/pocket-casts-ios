import PocketCastsServer
import XCTest

@testable import podcasts

final class SyncSigninErrorMessageTests: XCTestCase {
    func testServerFailureDoesNotBlameCredentials() {
        XCTAssertEqual(SyncSigninViewModel.errorMessage(for: nil), L10n.accountSsoFailed)
        XCTAssertEqual(SyncSigninViewModel.errorMessage(for: .UNKNOWN), L10n.accountSsoFailed)
    }

    func testServerRejectionShowsServerReason() {
        XCTAssertEqual(SyncSigninViewModel.errorMessage(for: .INCORRECT_PASSWORD), L10n.serverErrorLoginPasswordIncorrect)
        XCTAssertEqual(SyncSigninViewModel.errorMessage(for: .EMAIL_NOT_FOUND), L10n.serverErrorLoginEmailNotFound)
        XCTAssertEqual(SyncSigninViewModel.errorMessage(for: .NO_CONNECTION), L10n.playerErrorInternetConnection)
    }
}
