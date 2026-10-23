import XCTest
@testable import PocketCastsServer

final class SyncSettingsTaskTests: XCTestCase {
    private var uploads: [Api_NamedSettingsRequest] = []
    private var response = Api_NamedSettingsResponse()

    override func setUp() {
        super.setUp()
        uploads = []
        response = Api_NamedSettingsResponse()
        removeStoredValues()
        addTeardownBlock { [weak self] in
            self?.removeStoredValues()
        }
    }

    func testChangingTheGlobalPlaybackSpeedIsUploaded() throws {
        ServerSettings.setGlobalPlaybackSpeed(1.3)

        runTask()

        let upload = try XCTUnwrap(uploads.first)
        XCTAssertTrue(upload.settings.hasPlaybackSpeed)
        XCTAssertEqual(upload.settings.playbackSpeed.value, 1.3)
        XCTAssertFalse(ServerSettings.globalPlaybackSpeedNeedsSyncing())
    }

    func testSettingTheSameGlobalPlaybackSpeedIsNotUploaded() throws {
        ServerSettings.setGlobalPlaybackSpeed(1.3, syncChange: false)

        ServerSettings.setGlobalPlaybackSpeed(1.3)
        runTask()

        let upload = try XCTUnwrap(uploads.first)
        XCTAssertFalse(upload.settings.hasPlaybackSpeed)
    }

    func testChangingIncludeStarredIsUploaded() throws {
        ServerSettings.setAutoArchiveIncludesStarred(true)

        runTask()

        let upload = try XCTUnwrap(uploads.first)
        XCTAssertTrue(upload.settings.hasAutoArchiveIncludesStarred)
        XCTAssertTrue(upload.settings.autoArchiveIncludesStarred.value)
        XCTAssertFalse(ServerSettings.autoArchiveIncludesStarredNeedsSyncing())
    }

    func testUnchangedSettingsAreNotUploaded() throws {
        runTask()

        let upload = try XCTUnwrap(uploads.first)
        XCTAssertFalse(upload.settings.hasPlaybackSpeed)
        XCTAssertFalse(upload.settings.hasAutoArchiveIncludesStarred)
    }

    func testServerGlobalPlaybackSpeedIsApplied() {
        response.playbackSpeed.changed.value = true
        response.playbackSpeed.value.value = 1.7

        runTask()

        XCTAssertEqual(ServerSettings.globalPlaybackSpeed(), 1.7)
    }

    func testServerGlobalPlaybackSpeedIsNotUploadedBack() {
        response.playbackSpeed.changed.value = true
        response.playbackSpeed.value.value = 1.7

        runTask()
        runTask()

        XCTAssertEqual(uploads.count, 2)
        XCTAssertFalse(uploads[1].settings.hasPlaybackSpeed)
        XCTAssertFalse(ServerSettings.globalPlaybackSpeedNeedsSyncing())
    }

    func testUnchangedServerGlobalPlaybackSpeedIsIgnored() {
        ServerSettings.setGlobalPlaybackSpeed(1.3, syncChange: false)
        response.playbackSpeed.value.value = 2

        runTask()

        XCTAssertEqual(ServerSettings.globalPlaybackSpeed(), 1.3)
    }

    func testServerIncludeStarredIsApplied() {
        response.autoArchiveIncludesStarred.changed.value = true
        response.autoArchiveIncludesStarred.value.value = true

        runTask()

        XCTAssertTrue(ServerSettings.autoArchiveIncludesStarred())
    }

    func testServerIncludeStarredIsNotUploadedBack() {
        response.autoArchiveIncludesStarred.changed.value = true
        response.autoArchiveIncludesStarred.value.value = true

        runTask()
        runTask()

        XCTAssertEqual(uploads.count, 2)
        XCTAssertFalse(uploads[1].settings.hasAutoArchiveIncludesStarred)
        XCTAssertFalse(ServerSettings.autoArchiveIncludesStarredNeedsSyncing())
    }

    private func runTask() {
        let connection = URLConnection(mockHandler: { [unowned self] request in
            if let body = request.httpBody, let upload = try? Api_NamedSettingsRequest(serializedBytes: body) {
                uploads.append(upload)
            }
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: ServerConstants.HttpConstants.ok, httpVersion: nil, headerFields: nil)
            return (try response.serializedData(), httpResponse)
        })
        SyncSettingsTask(urlConnection: connection).apiTokenAcquired(token: "token")
    }

    private func removeStoredValues() {
        for key in [
            ServerConstants.UserDefaults.globalPlaybackSpeedKey,
            ServerConstants.UserDefaults.globalPlaybackSpeedNeedsSyncKey,
            ServerConstants.UserDefaults.autoArchiveIncludesStarredKey,
            ServerConstants.UserDefaults.autoArchiveIncludesStarredNeedsSyncKey
        ] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
