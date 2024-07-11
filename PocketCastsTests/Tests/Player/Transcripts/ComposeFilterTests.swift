import XCTest

@testable import podcasts

final class ComposeFilterTests: XCTestCase {

    func testNormalString() throws {
        let transcript = """
        This content should not change
        """

        let filtered = ComposeFilter.transcriptFilter.filter(transcript)

        XCTAssertEqual(filtered, "This content should not change")
    }

}
