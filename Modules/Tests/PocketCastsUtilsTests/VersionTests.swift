@testable import PocketCastsUtils
import XCTest

final class VersionTests: XCTestCase {
    func testParsesTheComponentsOfADottedVersion() throws {
        XCTAssertEqual(Version("7")?.components, [7])
        XCTAssertEqual(Version("7.43")?.components, [7, 43])
        XCTAssertEqual(Version("7.43.1")?.components, [7, 43, 1])
        XCTAssertEqual(Version("7.43.0.1")?.components, [7, 43, 0, 1])
    }

    func testRejectsAnythingThatIsNotADottedVersion() {
        XCTAssertNil(Version(""))
        XCTAssertNil(Version("7.43-beta"))
        XCTAssertNil(Version("v7.43"))
        XCTAssertNil(Version("7."))
        XCTAssertNil(Version("7..1"))
        XCTAssertNil(Version("7.43 (1234)"))
        XCTAssertNil(Version("-7.43"))
    }

    /// Comparing versions as text would put 7.10 before 7.9.
    func testOrdersComponentsAsNumbersRatherThanText() throws {
        try XCTAssertGreaterThan(version("7.10"), version("7.9"))
        try XCTAssertGreaterThan(version("7.43.10"), version("7.43.9"))
        try XCTAssertLessThan(version("7.43"), version("8.0"))
    }

    func testAShorterVersionIsPaddedAgainstALongerOne() throws {
        try XCTAssertEqual(version("7.43"), version("7.43.0"))
        try XCTAssertEqual(version("7.43"), version("7.43.0.0"))
        try XCTAssertLessThan(version("7.43"), version("7.43.1"))
        try XCTAssertGreaterThan(version("7.43.1"), version("7.43"))
    }

    func testEqualVersionsHashTheSame() throws {
        try XCTAssertEqual(Set([version("7.43"), version("7.43.0")]).count, 1)
    }

    /// The trailing zeros a version is written with aren't worth carrying, but everything the
    /// version actually says has to survive the round trip.
    func testDescriptionRoundTrips() throws {
        try XCTAssertEqual(version("7.43.1").description, "7.43.1")
        try XCTAssertEqual(version("7.43.0").description, "7.43")
        try XCTAssertEqual(version("0").description, "0")
    }

    private func version(_ string: String) throws -> Version {
        try XCTUnwrap(Version(string), "\(string) should parse as a version")
    }
}
