import Foundation
@testable import PocketCastsUtils
import XCTest

final class ISO8601DateParserTests: XCTestCase {
    /// The previous implementation: `ServerPodcastManager.isoFormatter`, a default `ISO8601DateFormatter`.
    private let previousFormatter = ISO8601DateFormatter()

    private func assertSameAsPrevious(_ string: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(ISO8601DateParser.date(from: string), previousFormatter.date(from: string), string, file: file, line: line)
    }

    func testMatchesPreviousImplementationForRandomTimestamps() throws {
        var generator = SplitMix64(seed: 1070)
        let earliest = try Int64(XCTUnwrap(previousFormatter.date(from: "0001-01-01T00:00:00Z")).timeIntervalSince1970)
        let latest = try Int64(XCTUnwrap(previousFormatter.date(from: "9999-12-31T23:59:59Z")).timeIntervalSince1970)

        for _ in 0..<10_000 {
            let date = Date(timeIntervalSince1970: TimeInterval(Int64.random(in: earliest...latest, using: &generator)))
            let string = previousFormatter.string(from: date)

            XCTAssertEqual(ISO8601DateParser.date(from: string), date, string)
            assertSameAsPrevious(string)
        }
    }

    func testMatchesPreviousImplementationForRandomFields() {
        var generator = SplitMix64(seed: 8_601)

        for _ in 0..<10_000 {
            assertSameAsPrevious(randomDateTime(using: &generator) + "Z")
        }
    }

    func testMatchesPreviousImplementationForTimeZoneOffsets() {
        var generator = SplitMix64(seed: 2_026)

        for _ in 0..<5_000 {
            let dateTime = randomDateTime(using: &generator)
            let offset = Int.random(in: -56...56, using: &generator) * 15
            let sign = offset < 0 ? "-" : "+"
            let hours = String(format: "%02d", abs(offset) / 60)
            let minutes = String(format: "%02d", abs(offset) % 60)

            assertSameAsPrevious("\(dateTime)\(sign)\(hours):\(minutes)")
            assertSameAsPrevious("\(dateTime)\(sign)\(hours)\(minutes)")
        }
    }

    func testEdges() {
        let expected: [String: TimeInterval] = [
            "0001-01-01T00:00:00Z": -62_135_769_600,
            "1582-10-04T00:00:00Z": -12_219_379_200,
            "1582-10-15T00:00:00Z": -12_219_292_800,
            "1583-01-01T00:00:00Z": -12_212_553_600,
            "1900-01-01T00:00:00Z": -2_208_988_800,
            "1969-12-31T23:59:59Z": -1,
            "1970-01-01T00:00:00Z": 0,
            "2000-02-29T12:00:00Z": 951_825_600,
            "2023-12-31T23:59:59Z": 1_704_067_199,
            "2024-01-01T00:00:00Z": 1_704_067_200,
            "2024-02-29T23:59:59Z": 1_709_251_199,
            "2024-03-01T00:00:00Z": 1_709_251_200,
            "2038-01-19T03:14:08Z": 2_147_483_648,
            "2100-02-28T23:59:59Z": 4_107_542_399,
            "2100-03-01T00:00:00Z": 4_107_542_400,
            "9999-12-31T23:59:59Z": 253_402_300_799,
            "2024-01-01T00:00:00+10:00": 1_704_031_200,
            "2024-01-01T00:00:00-05:00": 1_704_085_200,
            "2024-01-01T00:00:00+00:00": 1_704_067_200
        ]

        for (string, interval) in expected {
            XCTAssertEqual(ISO8601DateParser.date(from: string), Date(timeIntervalSince1970: interval), string)
            assertSameAsPrevious(string)
        }
    }

    func testRealServerDates() {
        let strings = [
            "1998-10-15T08:00:00Z",
            "1998-10-22T08:00:00Z",
            "2011-05-05T15:15:42Z",
            "2016-10-09T23:58:47Z",
            "2017-03-02T16:14:22Z",
            "2018-01-23T09:00:00Z",
            "2018-04-03T06:34:02Z",
            "2019-06-06T07:30:00Z",
            "2019-11-01T20:05:59Z",
            "2020-02-12T00:52:00Z",
            "2021-04-06T04:03:33Z",
            "2021-05-28T22:02:41Z",
            "2021-10-21T16:00:00Z",
            "2022-08-27T16:00:36Z",
            "2024-04-06T07:30:16Z",
            "2024-05-02T19:49:00Z",
            "2025-05-21T23:05:00Z",
            "2025-07-07T00:00:00Z",
            "2025-08-16T05:00:00Z",
            "2026-05-20T04:05:00Z",
            "2026-05-22T04:00:00Z",
            "2026-09-05T06:30:00Z",
            "2026-09-16T19:29:00Z",
            "2026-10-03T07:00:53Z",
            "2026-11-05T09:05:00Z",
            "2026-11-06T11:10:06Z",
            "2026-11-11T04:00:00Z",
            "2026-11-19T05:00:00Z"
        ]

        for string in strings {
            XCTAssertNotNil(ISO8601DateParser.date(from: string), string)
            assertSameAsPrevious(string)
        }
    }

    func testInvalidInputs() {
        let strings = [
            "",
            "2024-01-01",
            "2024-01-01T00:00:00",
            "2024-01-01T00:00Z",
            "2024-13-01T00:00:00Z",
            "2024-00-10T00:00:00Z",
            "2024-01-32T00:00:00Z",
            "abcd-ef-ghTij:kl:mnZ"
        ]

        for string in strings {
            XCTAssertNil(ISO8601DateParser.date(from: string), string)
            XCTAssertNil(previousFormatter.date(from: string), string)
        }
    }

    private func randomDateTime(using generator: inout SplitMix64) -> String {
        let year = Int.random(in: 0...9999, using: &generator)
        let month = Int.random(in: 1...12, using: &generator)
        let isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        let daysInMonth = month == 2 ? (isLeapYear ? 29 : 28) : ([4, 6, 9, 11].contains(month) ? 30 : 31)
        return String(
            format: "%04ld-%02ld-%02ldT%02ld:%02ld:%02ld",
            year,
            month,
            Int.random(in: 1...daysInMonth, using: &generator),
            Int.random(in: 0...23, using: &generator),
            Int.random(in: 0...59, using: &generator),
            Int.random(in: 0...59, using: &generator)
        )
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
