import Foundation
@testable import PocketCastsServer
import XCTest

class URLRequestTests: XCTestCase {

    override class func tearDown() {
        LocalizationHelper.provider = nil
        super.tearDown()
    }

    func testURLRequestLocalizationHeaders() throws {
        let provider = InternationalizationProvider(
            userRegion: "en",
            appLanguage: "en-US"
        )
        LocalizationHelper.provider = provider

        let url = try XCTUnwrap(URL(string: "https://api.pocketcasts.com/"))
        var request = URLRequest(url: url)
        request.addLocalizationHeaders()

        XCTAssertEqual(request.value(forHTTPHeaderField: ServerConstants.HttpHeaders.userRegion), "en")
        XCTAssertEqual(request.value(forHTTPHeaderField: ServerConstants.HttpHeaders.appLanguage), "en-US")

        let externalURL = try XCTUnwrap(URL(string: "https://wordpress.com/"))
        var newRequest = URLRequest(url: externalURL)
        newRequest.addLocalizationHeaders()

        XCTAssertNil(newRequest.value(forHTTPHeaderField: ServerConstants.HttpHeaders.userRegion))
        XCTAssertNil(newRequest.value(forHTTPHeaderField: ServerConstants.HttpHeaders.appLanguage))
    }
}
