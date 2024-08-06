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
}

fileprivate class ABTestProviderMock: ABTestProviding {
    var experiments: [String] = []

    func variation(for abTest: podcasts.ABTest) -> Variation {
        experiments.contains(abTest.rawValue) ? .treatment : .control
    }

    func start() async {
        experiments = ABTest.allCases.map { $0.rawValue }
    }
}
