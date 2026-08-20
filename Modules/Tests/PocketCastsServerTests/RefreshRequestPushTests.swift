@testable import PocketCastsServer
@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import XCTest

final class RefreshRequestPushTests: XCTestCase {
    private var previousDelegate: ServerSyncDelegate?

    override func setUp() {
        previousDelegate = ServerConfig.shared.syncDelegate
    }

    override func tearDown() {
        ServerConfig.shared.syncDelegate = previousDelegate
        FeatureFlagMock().reset()
    }

    func testAllPodcastsOptedOutWhenNewEpisodeNotificationsDisabled() throws {
        FeatureFlagMock().set(.newEpisodeNotificationsPushOptOut, value: true)
        ServerConfig.shared.syncDelegate = MockSyncDelegate(pushEnabled: true, newEpisodeNotificationsEnabled: false)

        let request = try XCTUnwrap(MainServerHandler.shared.createRefreshRequest(podcasts: podcasts(pushEnabled: [true, true, true])))

        XCTAssertEqual(try value(forKey: "push_messages_on", in: request), "000")
    }

    func testPushStaysOnWhenNewEpisodeNotificationsDisabled() throws {
        FeatureFlagMock().set(.newEpisodeNotificationsPushOptOut, value: true)
        ServerConfig.shared.syncDelegate = MockSyncDelegate(pushEnabled: true, newEpisodeNotificationsEnabled: false)

        let request = try XCTUnwrap(MainServerHandler.shared.createRefreshRequest(podcasts: podcasts(pushEnabled: [true])))

        XCTAssertEqual(try value(forKey: "push_on", in: request), "true")
    }

    func testPerPodcastSettingIsUsedWhenNewEpisodeNotificationsEnabled() throws {
        FeatureFlagMock().set(.newEpisodeNotificationsPushOptOut, value: true)
        ServerConfig.shared.syncDelegate = MockSyncDelegate(pushEnabled: true, newEpisodeNotificationsEnabled: true)

        let request = try XCTUnwrap(MainServerHandler.shared.createRefreshRequest(podcasts: podcasts(pushEnabled: [true, false, true])))

        XCTAssertEqual(try value(forKey: "push_messages_on", in: request), "101")
    }

    func testNewEpisodeNotificationsSettingIsIgnoredWhenFlagIsDisabled() throws {
        FeatureFlagMock().set(.newEpisodeNotificationsPushOptOut, value: false)
        ServerConfig.shared.syncDelegate = MockSyncDelegate(pushEnabled: true, newEpisodeNotificationsEnabled: false)

        let request = try XCTUnwrap(MainServerHandler.shared.createRefreshRequest(podcasts: podcasts(pushEnabled: [true, true, true])))

        XCTAssertEqual(try value(forKey: "push_messages_on", in: request), "111")
    }

    // MARK: - Helpers

    private func podcasts(pushEnabled: [Bool]) -> [Podcast] {
        pushEnabled.map { enabled in
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString
            podcast.pushEnabled = enabled

            return podcast
        }
    }

    private func value(forKey key: String, in request: URLRequest) throws -> String {
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        return try XCTUnwrap(json[key] as? String)
    }
}

private class MockSyncDelegate: ServerSyncDelegate, FilePathProtocol {
    private let pushEnabled: Bool
    private let newEpisodeNotificationsEnabled: Bool

    init(pushEnabled: Bool, newEpisodeNotificationsEnabled: Bool) {
        self.pushEnabled = pushEnabled
        self.newEpisodeNotificationsEnabled = newEpisodeNotificationsEnabled
    }

    func isPushEnabled() -> Bool { pushEnabled }
    func isNewEpisodeNotificationsEnabled() -> Bool { newEpisodeNotificationsEnabled }

    func podcastUpdated(podcastUuid: String) {}
    func podcastAdded(podcastUuid: String) {}
    func checkForUnusedPodcasts() {}
    func applyAutoArchivingToAllPodcasts() {}
    func subscribedToPodcast() {}
    func playlistChanged() {}
    func episodeStarredChanged(episode: Episode) {}
    func archiveEpisodeExternal(episode: Episode) {}
    func markEpisodeAsPlayedExternal(episode: Episode) {}
    func deselectedChaptersChanged() {}
    func episodeCanBeCleanedUp(episode: Episode) -> Bool { false }
    func autoDownloadLatestEpisodes(uuids: [String]) {}
    func cleanupAllUnusedEpisodeBuffers() {}
    func deleteFromDevice(userEpisode: UserEpisode) {}
    func autoDownloadUserEpisodes(episodes: [UserEpisode]) {}
    func userEpisodeFileProtocol() -> FilePathProtocol { self }
    func cleanupCloudOnlyFiles() {}
    func performActionsAfterSync() {}
    func defaultPodcastGrouping() -> Int32 { 0 }
    func defaultShowArchived() -> Bool { false }
    func uniqueAppId() -> String { "test-app-id" }
    func appVersion() -> String { "1.0" }
    func privateUserAgent() -> String { "Tests" }
    func minTimeBetweenProgressSaves() -> Double { 0 }
    func production() -> Bool { false }

    func tempPathForEpisode(_ episode: BaseEpisode) -> String { "" }
    func pathForEpisode(_ episode: BaseEpisode) -> String { "" }
    func streamingBufferPathForEpisode(_ episode: BaseEpisode) -> String { "" }
}
