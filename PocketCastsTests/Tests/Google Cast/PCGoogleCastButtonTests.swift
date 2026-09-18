import XCTest

@testable import podcasts

@MainActor
final class PCGoogleCastButtonTests: XCTestCase {
    func testLabelIsCastTo() {
        let button = PCGoogleCastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))

        XCTAssertEqual(button.accessibilityLabel, L10n.chromecastCastTo)
    }
}
