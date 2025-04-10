import Foundation
import XCTest

@testable import podcasts

final class InformationalBannerViewModelTests: XCTestCase {
    func testBannerInFilters() throws {
        var didCloseButtonTap = false
        var didCreateButtonTap = false
        let viewModel = InformationalBannerViewModel(bannerType: .filters)
        viewModel.onCloseBannerTap = {
            didCloseButtonTap = true
        }
        viewModel.onCreateFreeAccountTap = {
            didCreateButtonTap = true
        }
        XCTAssertEqual(viewModel.bannerType, .filters)
        viewModel.closeBanner()
        viewModel.createFreeAccount()
        XCTAssertTrue(didCloseButtonTap)
        XCTAssertTrue(didCreateButtonTap)
    }

    func testBannerInListenHistory() throws {
        var didCloseButtonTap = false
        var didCreateButtonTap = false
        let viewModel = InformationalBannerViewModel(bannerType: .listeningHistory)
        viewModel.onCloseBannerTap = {
            didCloseButtonTap = true
        }
        viewModel.onCreateFreeAccountTap = {
            didCreateButtonTap = true
        }
        XCTAssertEqual(viewModel.bannerType, .listeningHistory)
        viewModel.closeBanner()
        viewModel.createFreeAccount()
        XCTAssertTrue(didCloseButtonTap)
        XCTAssertTrue(didCreateButtonTap)
    }

    func testBannerInProfile() throws {
        var didCloseButtonTap = false
        var didCreateButtonTap = false
        let viewModel = InformationalBannerViewModel(bannerType: .profile)
        viewModel.onCloseBannerTap = {
            didCloseButtonTap = true
        }
        viewModel.onCreateFreeAccountTap = {
            didCreateButtonTap = true
        }
        XCTAssertEqual(viewModel.bannerType, .profile)
        viewModel.closeBanner()
        viewModel.createFreeAccount()
        XCTAssertTrue(didCloseButtonTap)
        XCTAssertTrue(didCreateButtonTap)
    }
}
