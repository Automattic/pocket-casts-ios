import XCTest

@testable import podcasts

final class WhatsNewLinkTests: XCTestCase {
    func testAppSchemeIsADeepLink() throws {
        let url = try XCTUnwrap(URL(string: "pktc://playlists"))

        XCTAssertEqual(WhatsNewLink(url: url), .deepLink(url))
    }

    /// The catalog is written once for every client, so the scheme the contract publishes has to
    /// resolve to the one this app registers.
    func testContractSchemeIsRewrittenToTheAppScheme() throws {
        let url = try XCTUnwrap(URL(string: "pocketcasts://upnext?source=whats_new"))
        let expected = try XCTUnwrap(URL(string: "pktc://upnext?source=whats_new"))

        XCTAssertEqual(WhatsNewLink(url: url), .deepLink(expected))
    }

    func testSchemeMatchingIgnoresCase() throws {
        let url = try XCTUnwrap(URL(string: "PKTC://playlists"))

        XCTAssertEqual(WhatsNewLink(url: url), .deepLink(url))
    }

    func testHTTPSIsAWebLink() throws {
        let url = try XCTUnwrap(URL(string: "https://blog.pocketcasts.com/whats-new"))

        XCTAssertEqual(WhatsNewLink(url: url), .web(url))
    }

    /// Everything else is dropped rather than handed to the system: the catalog is public and
    /// declarative, not a way to ask the app to open whatever a URL points at.
    func testEverythingElseIsRejected() throws {
        let urls = [
            "http://blog.pocketcasts.com",
            "mailto:support@pocketcasts.com",
            "tel:5551234",
            "itms-apps://apps.apple.com/app/id414834813",
            "file:///etc/passwd",
            "javascript:alert(1)",
            "some-other-app://open"
        ]

        for string in urls {
            let url = try XCTUnwrap(URL(string: string))
            XCTAssertNil(WhatsNewLink(url: url), "\(string) should not resolve to a link")
        }
    }

    func testAURLWithNoSchemeIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "pocketcasts.com/whats-new"))

        XCTAssertNil(WhatsNewLink(url: url))
    }
}
