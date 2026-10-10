import XCTest

@testable import podcasts
@testable import PocketCastsUtils

final class ExplicitBadgeHelperTests: XCTestCase {
    private let featureFlagMock = FeatureFlagMock()

    override func tearDown() {
        featureFlagMock.reset()
        super.tearDown()
    }

    func testAccessibilityTitleAnnouncesExplicitContent() {
        featureFlagMock.set(.showExplicitBadges, value: true)

        XCTAssertEqual(ExplicitBadgeHelper.accessibilityTitle("The Joe Rogan Experience"), "The Joe Rogan Experience, Explicit content")
    }

    func testAccessibilityTitleIsThePlainTitleWhenBadgesAreHidden() {
        featureFlagMock.set(.showExplicitBadges, value: false)

        XCTAssertEqual(ExplicitBadgeHelper.accessibilityTitle("The Joe Rogan Experience"), "The Joe Rogan Experience")
    }
}
