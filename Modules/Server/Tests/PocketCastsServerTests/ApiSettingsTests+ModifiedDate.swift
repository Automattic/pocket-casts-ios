import XCTest
@testable import PocketCastsServer
import PocketCastsUtils

class APISettingsTests: XCTestCase {
    /// Tests that the initial value is correct
    func testInitialValue() {
        var settings = Api_BoolSetting()
        let initialValue = true

        settings.value.value = initialValue

        XCTAssertEqual(settings.value.value, initialValue, "Initial value should be correct")
        XCTAssertEqual(settings.modifiedAt.timeIntervalSince1970, Date(timeIntervalSince1970: 0).timeIntervalSince1970, "Initial Timestamp should be epoch")
    }

    /// Tests that the value changes when a setting is updated
    func testChangedValue() {
        var settings = Api_BoolSetting()
        let initialValue = true
        let changedValue = false

        settings.value.value = initialValue

        var modifiedDate = ModifiedDate(wrappedValue: changedValue)
        settings.update(modifiedDate)

        XCTAssertNotEqual(settings.value.value, changedValue, "Settings value should not be changed by the initial value, since it wasn't modified")
        XCTAssertEqual(settings.modifiedAt.timeIntervalSince1970, Date(timeIntervalSince1970: 0).timeIntervalSince1970, "Initial Timestamp should be epoch")
    }

    /// Tests that the value changes when a setting is updated twice
    func testDoubleChangeValue() {
        var settings = Api_BoolSetting()
        let changedValue = false
        let secondChangedValue = true

        var modifiedDate = ModifiedDate(wrappedValue: changedValue)
        settings.update(modifiedDate)

        let date = Date()
        modifiedDate.wrappedValue = secondChangedValue
        settings.update(modifiedDate)

        XCTAssertEqual(settings.value.value, secondChangedValue, "Changed value should be correct")
        XCTAssertEqual(settings.modifiedAt.timeIntervalSinceReferenceDate, date.timeIntervalSinceReferenceDate, accuracy: 0.01, "Initial Timestamp should be nil?")

    }
}
