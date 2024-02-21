import XCTest
@testable import podcasts
@testable import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

final class SettingsTests: XCTestCase {

    private let userDefaultsSuiteName = "PocketCasts-SettingsTests"

    private var overriddenFlags = [FeatureFlag: Bool]()

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    private func override(flag: FeatureFlag, value: Bool) throws {
        overriddenFlags[flag] = flag.enabled
        try FeatureFlagOverrideStore().override(flag, withValue: value)
    }

    private func reset(flag: FeatureFlag) throws {
        if let oldValue = overriddenFlags[flag] {
            try FeatureFlagOverrideStore().override(flag, withValue: oldValue)
        }
    }

    private func setupSettingsStore() throws {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")
        SettingsStore.appSettings = SettingsStore(userDefaults: userDefaults, key: "app_settings", value: AppSettings.defaults)
    }

    func testImportOldHeadphoneControls() throws {
        try override(flag: .settingsSync, value: false)
        try setupSettingsStore()

        let newNextAction = HeadphoneControlAction.nextChapter
        let newPreviousAction = HeadphoneControlAction.previousChapter

        Settings.headphonesNextAction = newNextAction
        Settings.headphonesPreviousAction = newPreviousAction

        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: true)

        SettingsStore.appSettings.importUserDefaults()

        XCTAssertEqual(newNextAction, Settings.headphonesNextAction, "Next action should be imported from old defaults")
        XCTAssertEqual(newPreviousAction, Settings.headphonesPreviousAction, "Previous action should be imported from old defaults")

        try reset(flag: .settingsSync)
    }
}
