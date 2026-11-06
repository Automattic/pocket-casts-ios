import Foundation
@testable import PocketCastsUtils
import XCTest

final class ISO8601DateParserTests: XCTestCase {
    private let formatter = ISO8601DateFormatter()

    func testFastPathMatchesFormatterForRandomTimestamps() throws {
        var generator = SplitMix64(seed: 1070)
        let earliest = try Int64(XCTUnwrap(formatter.date(from: "1583-01-01T00:00:00Z")).timeIntervalSince1970)
        let latest = try Int64(XCTUnwrap(formatter.date(from: "9999-12-31T23:59:59Z")).timeIntervalSince1970)

        for _ in 0..<20_000 {
            let date = Date(timeIntervalSince1970: TimeInterval(Int64.random(in: earliest...latest, using: &generator)))
            let string = formatter.string(from: date)

            XCTAssertEqual(ISO8601DateParser.fastDate(from: string), date, string)
            XCTAssertEqual(ISO8601DateParser.date(from: string), formatter.date(from: string), string)
        }
    }

    func testMatchesFormatterForRandomFields() {
        var generator = SplitMix64(seed: 8_601)

        for _ in 0..<20_000 {
            let string = String(
                format: "%04ld-%02ld-%02ldT%02ld:%02ld:%02ldZ",
                Int.random(in: 0...9999, using: &generator),
                Int.random(in: 0...13, using: &generator),
                Int.random(in: 0...32, using: &generator),
                Int.random(in: 0...25, using: &generator),
                Int.random(in: 0...60, using: &generator),
                Int.random(in: 0...60, using: &generator)
            )

            XCTAssertEqual(ISO8601DateParser.date(from: string), formatter.date(from: string), string)
        }
    }

    func testEdges() {
        let expected: [String: TimeInterval] = [
            "1970-01-01T00:00:00Z": 0,
            "1969-12-31T23:59:59Z": -1,
            "1900-01-01T00:00:00Z": -2_208_988_800,
            "1583-01-01T00:00:00Z": -12_212_553_600,
            "2000-02-29T12:00:00Z": 951_825_600,
            "2024-02-29T23:59:59Z": 1_709_251_199,
            "2023-12-31T23:59:59Z": 1_704_067_199,
            "2024-01-01T00:00:00Z": 1_704_067_200,
            "2024-03-01T00:00:00Z": 1_709_251_200,
            "2038-01-19T03:14:08Z": 2_147_483_648,
            "2100-02-28T23:59:59Z": 4_107_542_399,
            "2100-03-01T00:00:00Z": 4_107_542_400,
            "9999-12-31T23:59:59Z": 253_402_300_799
        ]

        for (string, interval) in expected {
            XCTAssertEqual(ISO8601DateParser.fastDate(from: string), Date(timeIntervalSince1970: interval), string)
            XCTAssertEqual(ISO8601DateParser.date(from: string), formatter.date(from: string), string)
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
            XCTAssertNotNil(ISO8601DateParser.fastDate(from: string), string)
            XCTAssertEqual(ISO8601DateParser.fastDate(from: string), formatter.date(from: string), string)
        }
    }

    func testUnexpectedInputsFallBackToFormatter() {
        let strings = [
            "",
            "2024-01-01",
            "2024-01-01T00:00:00",
            "2024-01-01T00:00Z",
            "2024-01-01T00:00:00z",
            "2024-01-01t00:00:00Z",
            "2024-01-01T00:00:00.123Z",
            "2024-01-01T00:00:00.000Z",
            "2024-01-01T00:00:00+10:00",
            "2024-01-01T00:00:00+00:00",
            "2024-01-01T00:00:00-05:00",
            "2024-01-01T00:00:00-0500",
            "2024-01-01T00:00:00Zjunk",
            "2024-01-01T00:00:00Z ",
            " 2024-01-01T00:00:00Z",
            "2024-13-01T00:00:00Z",
            "2024-00-10T00:00:00Z",
            "2024-01-00T00:00:00Z",
            "2024-01-32T00:00:00Z",
            "2023-02-29T00:00:00Z",
            "2024-02-30T00:00:00Z",
            "2024-04-31T00:00:00Z",
            "2024-01-01T24:00:00Z",
            "2024-01-01T25:00:00Z",
            "2024-01-01T23:60:00Z",
            "2024-01-01T23:59:60Z",
            "2024-1-01T00:00:00Z",
            "20240101T000000Z",
            "2024-01-01 00:00:00Z",
            "2024/01/01T00:00:00Z",
            "+2024-01-01T00:00:00Z",
            "-2024-01-01T00:00:00Z",
            "12024-01-01T00:00:00Z",
            "２０２４-01-01T00:00:00Z",
            "abcd-ef-ghTij:kl:mnZ",
            "1582-12-31T23:59:59Z",
            "1582-10-15T00:00:00Z",
            "1582-10-04T00:00:00Z",
            "0001-01-01T00:00:00Z",
            "0000-01-01T00:00:00Z"
        ]

        for string in strings {
            XCTAssertNil(ISO8601DateParser.fastDate(from: string), string)
            XCTAssertEqual(ISO8601DateParser.date(from: string), formatter.date(from: string), string)
        }
        XCTAssertEqual(ISO8601DateParser.date(from: "2024-01-01T00:00:00+10:00"), Date(timeIntervalSince1970: 1_704_031_200))
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
