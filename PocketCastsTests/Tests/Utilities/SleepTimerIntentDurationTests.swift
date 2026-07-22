import XCTest
@testable import podcasts

final class SleepTimerIntentDurationTests: XCTestCase {
    func testMigratedValuePreservesLegacySeconds() {
        let duration = SleepTimerIntentDuration.migratedValue(1_800, defaultDuration: 300)

        XCTAssertEqual(duration, 1_800)
    }

    func testMigratedValueUsesDefaultWhenLegacyValueIsMissing() {
        let duration = SleepTimerIntentDuration.migratedValue(nil, defaultDuration: 1_800)

        XCTAssertEqual(duration, 1_800)
    }

    func testMigratedValueUsesDefaultWhenLegacyValueIsNotPositive() {
        XCTAssertEqual(SleepTimerIntentDuration.migratedValue(0, defaultDuration: 1_800), 1_800)
        XCTAssertEqual(SleepTimerIntentDuration.migratedValue(-1, defaultDuration: 1_800), 1_800)
    }
}
