import Foundation
import XCTest

@testable import podcasts

final class InformationalBannerViewCoordinatorTests: XCTestCase {
    func testCoordinatorDismiss() throws {
        let vm = MockViewModel(bannerType: .profile)
        let coordinator = MockCoordinator(viewModel: vm)
        vm.closeBanner()
        XCTAssertTrue(coordinator.didDismissBanner)
    }

    func testCoordinatorPresent() throws {
        let vm = MockViewModel(bannerType: .profile)
        let coordinator = MockCoordinator(viewModel: vm)
        vm.createFreeAccount()
        XCTAssertTrue(coordinator.didPresentLoginFlow)
    }
}

fileprivate class MockViewModel: InformationalBannerPresenting {
    let bannerType: InformationalBannerType

    var onCloseBannerTap: (() -> Void)? = nil
    var onCreateFreeAccountTap: (() -> Void)? = nil

    init(bannerType: InformationalBannerType) {
        self.bannerType = bannerType
    }
}

fileprivate class MockCoordinator: InformationalBannerViewCoordinator {
    var didDismissBanner = false
    var didPresentLoginFlow = false

    override func dismissBanner() {
        didDismissBanner = true
    }

    override func presentLoginFlow() {
        didPresentLoginFlow = true
    }
}
