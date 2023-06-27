import XCTest

@testable import podcasts

final class AnalyticsCoordinatorTests: XCTestCase {
    func testFallsBackToPreviousSourceOnNilCurrentSource() {
        let coordinator = AnalyticsCoordinator()
        coordinator.currentSource = .carPlay

        // Resets the current source and sets the previous source
        let previousSource = coordinator.currentAnalyticsSource

        // The current source is expected to be nil, so this should reset to the original source value
        coordinator.fallbackToPreviousSourceIfNeeded()

        XCTAssertEqual(previousSource, coordinator.currentSource)
    }

    func testFallsBackToPreviousSourceOnUnknownCurrentSource() {
        let coordinator = AnalyticsCoordinator()
        coordinator.currentSource = .carPlay

        // Resets the current source and sets the previous source
        let _ = coordinator.currentAnalyticsSource
        coordinator.currentSource = .unknown

        // The current source is expected to be nil, so this should reset to the original source value
        coordinator.fallbackToPreviousSourceIfNeeded()

        XCTAssertEqual(coordinator.currentSource, .carPlay)
    }

    func testFallbackDoesntHappenIfCurrentSourceIsSet() {
        let coordinator = AnalyticsCoordinator()
        coordinator.currentSource = .carPlay

        // Resets the current source and sets the previous source
        let _ = coordinator.currentAnalyticsSource
        coordinator.currentSource = .chooseFolder

        // The current source is set, this should do nothing
        coordinator.fallbackToPreviousSourceIfNeeded()

        XCTAssertEqual(coordinator.currentSource, .chooseFolder)
    }
}
