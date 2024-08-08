import XCTest
import AutomatticTracks

@testable import podcasts

final class ABTestProviderTests: XCTestCase {

    func testVariation() throws {
        Task { @MainActor in
            let abTestProvider = ABTestProviderMock()
            await abTestProvider.start()
            let variation = abTestProvider.variation(for: .pocketcastsPaywallAATest)
            XCTAssertEqual(variation, .treatment)
        }
    }

    func testReload() throws {
        let platform = "pocketcasts"
        let abTestProvider = ABTestProviderMock()
        abTestProvider.reloadExPlat(platform: platform)
        XCTAssertEqual(abTestProvider.platform, platform)
    }
}

fileprivate class ABTestProviderMock: ABTestProviding {
    var experiments: [String] = []

    private(set) var platform: String = "default"

    func variation(for abTest: podcasts.ABTest) -> Variation {
        experiments.contains(abTest.rawValue) ? .treatment : .control
    }

    func start() async {
        experiments = ABTest.allCases.map { $0.rawValue }
    }

    func reloadExPlat(platform: String, oAuthToken: String? = nil, userAgent: String? = nil, anonId: String? = nil) {
        self.platform = platform
    }
}
