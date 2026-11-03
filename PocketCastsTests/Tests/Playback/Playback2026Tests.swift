import XCTest
import PocketCastsUtils
@testable import podcasts

final class Playback2026Tests: XCTestCase {
    func testFlagOffIsNeverAvailable() {
        let inRange = Playback2026.availableFrom.addingTimeInterval(1)
        XCTAssertFalse(Playback2026.isAvailable(now: inRange, isFlagEnabled: false, buildEnvironment: .appStore))
        XCTAssertFalse(Playback2026.isAvailable(now: inRange, isFlagEnabled: false, buildEnvironment: .testFlight))
    }

    func testAppStoreIsAvailableOnlyInsideDateRange() {
        func isAvailable(_ date: Date) -> Bool {
            Playback2026.isAvailable(now: date, isFlagEnabled: true, buildEnvironment: .appStore)
        }

        XCTAssertFalse(isAvailable(Playback2026.availableFrom.addingTimeInterval(-1)))
        XCTAssertTrue(isAvailable(Playback2026.availableFrom))
        XCTAssertTrue(isAvailable(Playback2026.availableUntil.addingTimeInterval(-1)))
        XCTAssertFalse(isAvailable(Playback2026.availableUntil))
    }

    func testBetaBuildsIgnoreDateRange() {
        let early = Playback2026.availableFrom.addingTimeInterval(-86_400 * 90)
        XCTAssertTrue(Playback2026.isAvailable(now: early, isFlagEnabled: true, buildEnvironment: .testFlight))
        XCTAssertTrue(Playback2026.isAvailable(now: early, isFlagEnabled: true, buildEnvironment: .debug))
    }
}
