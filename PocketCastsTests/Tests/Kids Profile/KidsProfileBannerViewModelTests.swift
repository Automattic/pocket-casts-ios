import Foundation
import XCTest

@testable import podcasts

class KidsProfileBannerViewModelTests: XCTestCase {
    let viewModel = KidsProfileBannerViewModel()

    func testCloseButtonTap() {
        var didCloseButtonTap = false

        viewModel.onCloseButtonTap = {
            didCloseButtonTap = true
        }

        viewModel.closeButtonTap()

        XCTAssertTrue(didCloseButtonTap)
    }

    func testRequestEarlyAccessTap() throws {
        var didRequestEarlyAccessTap = false

        viewModel.onRequestEarlyAccessTap = {
            didRequestEarlyAccessTap = true
        }

        viewModel.requestEarlyAccessTap()

        XCTAssertTrue(didRequestEarlyAccessTap)
    }
}
