import Foundation
@testable import PocketCastsServer
import XCTest

final class LocalizationHelperTests: XCTestCase {

    override class func tearDown() {
        LocalizationHelper.provider = nil
        super.tearDown()
    }

    func testInternationalizationProvider() throws {
        let provider = InternationalizationProvider(
            userRegion: "en",
            appLanguage: "en-US",
            allowedHosts: [
                "https://refresh.pocketcasts.com/",
                "https://api.pocketcasts.com/"
            ]
                .compactMap { URL(string: $0)?.host }
                .reduce(into: Set<String>()) { $0.insert($1) }
        )

        XCTAssertTrue(provider.userRegion == "en")
        XCTAssertTrue(provider.appLanguage == "en-US")

        let url = try XCTUnwrap(URL(string: "https://api.pocketcasts.com/"))
        let host = try XCTUnwrap(url.host())
        XCTAssertTrue(provider.allowedHosts.contains(host))
    }

    func testLocalizationHelper() {
        let provider = InternationalizationProvider(
            userRegion: "en",
            appLanguage: "en-US",
            allowedHosts: [
                "https://refresh.pocketcasts.com/",
                "https://api.pocketcasts.com/"
            ]
                .compactMap { URL(string: $0)?.host }
                .reduce(into: Set<String>()) { $0.insert($1) }
        )
        LocalizationHelper.provider = provider

        XCTAssertTrue(LocalizationHelper.provider?.userRegion == "en")
        XCTAssertTrue(LocalizationHelper.provider?.appLanguage == "en-US")

        LocalizationHelper.update(userRegion: "it")

        XCTAssertTrue(LocalizationHelper.provider?.userRegion == "it")
    }

    /// Picking a Discover region replaces the provider on the main thread while API requests read it
    /// on background threads to add their headers (POCKET-CASTS-IOS-7C4).
    func testProviderReadAndReplacedFromManyThreads() throws {
        let url = try XCTUnwrap(URL(string: "https://api.pocketcasts.com/"))

        DispatchQueue.concurrentPerform(iterations: 100_000) { index in
            if index.isMultiple(of: 2) {
                LocalizationHelper.update(userRegion: index.isMultiple(of: 4) ? "us" : "au")
            } else {
                var request = URLRequest(url: url)
                request.addLocalizationHeaders()
            }
        }

        XCTAssertNotNil(LocalizationHelper.provider?.userRegion)
    }
}
