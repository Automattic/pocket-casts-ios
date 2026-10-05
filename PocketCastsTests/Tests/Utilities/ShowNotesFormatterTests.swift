import XCTest
@testable import podcasts

final class ShowNotesFormatterTests: XCTestCase {
    private let plainTimestampShowNotes = "<p>On Episode 668 of Spittin\u{2019} Chiclets.\n\n00:00:00 - START\n00:32:17 - Canucks/Kings\n01:20:31 - Craig Conroy/Flames\n04:01:57 - RA\u{2019}s World\n\nSupport the Show:</p>"

    private func format(_ showNotes: String, convertTimesToLinks: Bool) -> String {
        ShowNotesFormatter.format(showNotes: showNotes, tintColor: .blue, convertTimesToLinks: convertTimesToLinks, bgColor: nil, textColor: .black)
    }

    func testPlainTextTimestampsBecomeLinksWhenEnabled() {
        let result = format(plainTimestampShowNotes, convertTimesToLinks: true)

        XCTAssertTrue(result.contains("<a href=\"http://localhost/#playerJumpTo=00:00:00\">00:00:00</a> - START"))
        XCTAssertTrue(result.contains("<a href=\"http://localhost/#playerJumpTo=00:32:17\">00:32:17</a> - Canucks/Kings"))
        XCTAssertTrue(result.contains("<a href=\"http://localhost/#playerJumpTo=01:20:31\">01:20:31</a> - Craig Conroy/Flames"))
        XCTAssertTrue(result.contains("<a href=\"http://localhost/#playerJumpTo=04:01:57\">04:01:57</a> - RA\u{2019}s World"))
    }

    func testPlainTextTimestampsStayPlainWhenDisabled() {
        let result = format(plainTimestampShowNotes, convertTimesToLinks: false)

        XCTAssertFalse(result.contains("playerJumpTo"))
    }

    func testTimestampsInsideExistingLinksAreNotConverted() {
        let result = format("<p><a href=\"https://example.com/watch?t=1:02:03\">Watch at 1:02:03</a> and 00:05:00 - Intro</p>", convertTimesToLinks: true)

        XCTAssertTrue(result.contains("<a href=\"https://example.com/watch?t=1:02:03\">Watch at 1:02:03</a>"))
        XCTAssertTrue(result.contains("<a href=\"http://localhost/#playerJumpTo=00:05:00\">00:05:00</a> - Intro"))
    }

    func testJumpTimeParsesHoursMinutesSeconds() {
        let url = URL(string: "http://localhost/#playerJumpTo=01:20:31")!

        XCTAssertEqual(ShowNotesFormatter.jumpTime(from: url), 4831)
    }

    func testJumpTimeParsesMinutesSeconds() {
        let url = URL(string: "http://localhost/#playerJumpTo=6:20")!

        XCTAssertEqual(ShowNotesFormatter.jumpTime(from: url), 380)
    }

    func testJumpTimeIgnoresNonJumpLinks() {
        XCTAssertNil(ShowNotesFormatter.jumpTime(from: URL(string: "https://example.com/#playerJumpTo=00:10:00")!))
        XCTAssertNil(ShowNotesFormatter.jumpTime(from: URL(string: "http://localhost/#other=00:10:00")!))
        XCTAssertNil(ShowNotesFormatter.jumpTime(from: URL(string: "http://localhost/")!))
    }
}
