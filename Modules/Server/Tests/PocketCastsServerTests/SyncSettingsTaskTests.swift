import XCTest
@testable import PocketCastsServer
import SwiftProtobuf
@testable import PocketCastsUtils
import PocketCastsDataModel

class SyncSettingsTaskTests: XCTestCase {

    private let userDefaultsSuiteName = "PocketCastsTests-SyncSettingsTaskTests"
    private let defaultsKey = "app_settings"
    private let token = "1234"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        FeatureFlagMock().set(.settingsSync, value: true)
    }

    override func tearDown() {
        FeatureFlagMock().reset()
    }

    /// Tests sending a request with updates from `SettingsStore`
    func testRequest() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")

        XCTAssertNil(defaults.data(forKey: defaultsKey), "User Defaults data should not exist yet for \(defaultsKey)")

        let store = SettingsStore(userDefaults: defaults, key: defaultsKey, value: AppSettings())
        let changedValue = true
        let changedDate = Date()
        store.openLinks = changedValue

        let expectation = XCTestExpectation(description: "Request method should be called")
        let task = SyncSettingsTask(appSettings: store, urlConnection: URLConnection { urlRequest in

            let data = try XCTUnwrap(urlRequest.httpBody, "Request body should exist")
            let request = try Api_NamedSettingsRequest(serializedData: data)

            XCTAssertTrue(request.changedSettings.openLinks.hasValue, "Change value should be included")
            XCTAssertEqual(request.changedSettings.openLinks.modifiedAt.timeIntervalSinceReferenceDate, changedDate.timeIntervalSinceReferenceDate, accuracy: 0.01, "Modified at should be around the time the value was updated")
            XCTAssertEqual(request.changedSettings.openLinks.value.value, changedValue, "Value should be changed")
            XCTAssertFalse(request.changedSettings.rowAction.hasChanged, "Unchanged value should not be included")
            XCTAssertFalse(request.changedSettings.rowAction.hasValue, "Unchanged value should not be included")

            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)

            expectation.fulfill()
            return (Data(), response)
        })

        task.apiTokenAcquired(token: token)

        wait(for: [expectation])
    }

    /// Tests sending a response with updates from `SettingsStore`
    func testResponse() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")

        XCTAssertNil(defaults.data(forKey: defaultsKey), "User Defaults data should not exist yet for \(defaultsKey)")

        let store = SettingsStore(userDefaults: defaults, key: defaultsKey, value: AppSettings())
        let changedValue = true
        let changedDate = Date()

        XCTAssertFalse(store.openLinks, "Initial value should be false")

        let expectation = XCTestExpectation(description: "Request method should be called")
        let task = SyncSettingsTask(appSettings: store, urlConnection: URLConnection { urlRequest in

            var serverResponse = Api_NamedSettingsResponse()
            serverResponse.openLinks.value.value = changedValue
            serverResponse.openLinks.modifiedAt = Google_Protobuf_Timestamp(date: changedDate)
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)

            let data = try! XCTUnwrap(serverResponse.serializedData(), "Response should serialize to Data")

            expectation.fulfill()

            return (data, response)
        })

        task.apiTokenAcquired(token: token)

        wait(for: [expectation])

        XCTAssertEqual(store.openLinks, changedValue, "Value should be changed")
        XCTAssertNil(store.$openLinks.modifiedAt, "Modified date should be nil")
    }
}
