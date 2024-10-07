import XCTest
import AutomatticTracks

@testable import podcasts

final class ABTestProviderTests: XCTestCase {

    func testVariation() async throws {
        let abTestProvider = ABTestProviderMock()
        await abTestProvider.start()
        let variation = abTestProvider.variation(for: .pocketcastsPaywallAATest)
        XCTAssertNotNil(variation)
        XCTAssertEqual(variation, .treatment)
    }

    func testReload() throws {
        let platform = "pocketcasts"
        let abTestProvider = ABTestProviderMock()
        abTestProvider.reloadExPlat(platform: platform)
        XCTAssertEqual(abTestProvider.platform, platform)
    }

    func testCustomTreatment() async throws {
        let abTestProvider = ABTestProviderMock()
        await abTestProvider.start()
        let variation = abTestProvider.variation(for: .pocketcastsPaywallUpgradeIOSABTest)
        XCTAssertNotNil(variation)
        XCTAssertEqual(variation.getCustomTreatment(), .featuresTreatment)
    }
}

fileprivate class ABTestProviderMock: ABTestProviding {
    var experiments: [String] = []

    private(set) var platform: String = "default"

    func variation(for abTest: podcasts.ABTest) -> Variation {
        guard experiments.contains(abTest.rawValue) else {
            return .control
        }
        switch abTest {
        case .pocketcastsPaywallAATest:
            return .treatment
        case .pocketcastsPaywallUpgradeIOSABTest:
            return .customTreatment(name: "features_treatment")
        }
    }

    func start() async {
        experiments = ABTest.allCases.map { $0.rawValue }
    }

    func reloadExPlat(platform: String, oAuthToken: String? = nil, userAgent: String? = nil, anonId: String? = nil) {
        self.platform = platform
    }
}
