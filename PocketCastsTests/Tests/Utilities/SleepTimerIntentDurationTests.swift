import XCTest
@testable import podcasts

final class SleepTimerIntentDurationTests: XCTestCase {
    func testBoundedValuePreservesDurationWithinLimits() {
        XCTAssertEqual(SleepTimerIntentDuration.boundedValue(30.minutes), 30.minutes)
    }

    func testBoundedValueClampsToSleepTimerLimits() {
        XCTAssertEqual(SleepTimerIntentDuration.boundedValue(3), Constants.Limits.minSleepTime)
        XCTAssertEqual(SleepTimerIntentDuration.boundedValue(40.hours), Constants.Limits.maxSleepTime)
    }

    func testBoundedValueRejectsInvalidDuration() {
        XCTAssertNil(SleepTimerIntentDuration.boundedValue(0))
        XCTAssertNil(SleepTimerIntentDuration.boundedValue(-1))
        XCTAssertNil(SleepTimerIntentDuration.boundedValue(.infinity))
        XCTAssertNil(SleepTimerIntentDuration.boundedValue(.nan))
    }

    func testResolvedValueConvertsSelectedDurationToSeconds() {
        let duration = SleepTimerIntentDuration.resolvedValue(
            Measurement(value: 1.5, unit: UnitDuration.hours),
            defaultDuration: 300
        )

        XCTAssertEqual(duration, 5_400)
    }

    func testResolvedValueUsesDefaultWhenDurationIsMissing() {
        let duration = SleepTimerIntentDuration.resolvedValue(nil, defaultDuration: 1_800)

        XCTAssertEqual(duration, 1_800)
    }

    func testResolvedValueUsesDefaultWhenDurationIsInvalid() {
        XCTAssertEqual(
            SleepTimerIntentDuration.resolvedValue(
                Measurement(value: 0, unit: UnitDuration.minutes),
                defaultDuration: 1_800
            ),
            1_800
        )
        XCTAssertEqual(
            SleepTimerIntentDuration.resolvedValue(
                Measurement(value: -.infinity, unit: UnitDuration.seconds),
                defaultDuration: 1_800
            ),
            1_800
        )
    }

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
