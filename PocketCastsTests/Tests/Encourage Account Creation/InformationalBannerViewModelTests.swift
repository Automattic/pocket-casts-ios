import Foundation
import XCTest

@testable import podcasts

final class InformationalBannerViewModelTests: XCTestCase {
    let userDefaults = UserDefaults(suiteName: "InformationalBannerViewModelTests")

    override func tearDownWithError() throws {
        let dictionary = userDefaults?.dictionaryRepresentation()
        dictionary?.keys.forEach { key in
            userDefaults?.removeObject(forKey: key)
        }
    }

    func testBannerInFilters() throws {
        var didCloseButtonTap = false
        var didCreateButtonTap = false
        let userDefaults = try XCTUnwrap(userDefaults)
        let viewModel = InformationalBannerViewModel(bannerType: .filters, userDefaults: userDefaults)
        viewModel.onCloseBannerTap = {
            didCloseButtonTap = true
        }
        viewModel.onCreateFreeAccountTap = {
            didCreateButtonTap = true
        }
        XCTAssertTrue(viewModel.shouldShowBanner())
        viewModel.closeBanner()
        viewModel.createFreeAccount()
        XCTAssertTrue(didCloseButtonTap)
        XCTAssertTrue(didCreateButtonTap)
        XCTAssertFalse(viewModel.shouldShowBanner())
    }

    func testBannerInListenHistory() throws {
        var didCloseButtonTap = false
        var didCreateButtonTap = false
        let userDefaults = try XCTUnwrap(userDefaults)
        let viewModel = InformationalBannerViewModel(bannerType: .listenHistory, userDefaults: userDefaults)
        viewModel.onCloseBannerTap = {
            didCloseButtonTap = true
        }
        viewModel.onCreateFreeAccountTap = {
            didCreateButtonTap = true
        }
        XCTAssertTrue(viewModel.shouldShowBanner())
        viewModel.closeBanner()
        viewModel.createFreeAccount()
        XCTAssertTrue(didCloseButtonTap)
        XCTAssertTrue(didCreateButtonTap)
        XCTAssertFalse(viewModel.shouldShowBanner())
    }

    func testBannerInProfile() throws {
        var didCloseButtonTap = false
        var didCreateButtonTap = false
        let userDefaults = try XCTUnwrap(userDefaults)
        let viewModel = InformationalBannerViewModel(bannerType: .profile, userDefaults: userDefaults)
        viewModel.onCloseBannerTap = {
            didCloseButtonTap = true
        }
        viewModel.onCreateFreeAccountTap = {
            didCreateButtonTap = true
        }
        XCTAssertTrue(viewModel.shouldShowBanner())
        viewModel.closeBanner()
        viewModel.createFreeAccount()
        XCTAssertTrue(didCloseButtonTap)
        XCTAssertTrue(didCreateButtonTap)
        XCTAssertFalse(viewModel.shouldShowBanner())
    }
}
