import XCTest
import Foundation
import PocketCastsUtils
@testable import podcasts
import FMDB
import SQLite3
import PocketCastsDataModel
@testable import PocketCastsUtils

class PodcastSettingsImportUserDefaultsTests: XCTestCase {
    private let newOverrideGlobalEffects = true
    private let newAutoStartFrom: Int32 = 20
    private let newAutoSkipLast: Int32 = 30
    private let newBoostVolume = true
    private let newPlaybackSpeed = 2.0
    private let newPushEnabled = true
    private let newTrimSilence = TrimSilenceAmount.medium
    private let newOverrideGlobalArchive = true
    private let newArchivePlayedAfter = AutoArchiveAfterTime.after1Week
    private let newArchiveInactiveAfter = AutoArchiveAfterTime.after90Days
    private let newArchiveEpisodeLimit: Int32 = 3
    private let newUpNextPosition = AutoAddToUpNextSetting.addLast
    private let newEpisodeSortOrder = PodcastEpisodeSortOrder.Old.oldestToNewest
    private let newEpisodeGrouping = PodcastGrouping.starred
    private let newShowArchive = true

    private let dataManager = DataManagerMock()
    private let featureFlagMock = FeatureFlagMock()

    enum TestError: Error {
        case dbFolderPathFailure
    }

    override func setUp() {
        super.setUp()
        let podcast = Podcast()
        podcast.overrideGlobalEffects = newOverrideGlobalEffects
        podcast.autoStartFrom = newAutoStartFrom
        podcast.autoSkipLast = newAutoSkipLast
        podcast.trimSilenceAmount = newTrimSilence.rawValue
        podcast.boostVolume = newBoostVolume
        podcast.playbackSpeed = newPlaybackSpeed
        podcast.pushEnabled = newPushEnabled
        podcast.overrideGlobalArchive = newOverrideGlobalArchive
        podcast.autoArchivePlayedAfter = newArchivePlayedAfter.rawValue
        podcast.autoArchiveInactiveAfter = newArchiveInactiveAfter.rawValue
        podcast.autoArchiveEpisodeLimitCount = newArchiveEpisodeLimit
        podcast.autoAddToUpNext = newUpNextPosition.rawValue
        podcast.episodeSortOrder = newEpisodeSortOrder.rawValue
        podcast.episodeGrouping = newEpisodeGrouping.rawValue
        podcast.showArchived = newShowArchive
        dataManager.podcastsToReturn = [podcast]
    }

    private func setupDatabase() throws -> DataManager {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last as NSString?
        guard let dbFolderPath = documentsPath?.appendingPathComponent("Pocket Casts") as? NSString else {
            throw TestError.dbFolderPathFailure
        }

        if !FileManager.default.fileExists(atPath: dbFolderPath as String) {
            try FileManager.default.createDirectory(atPath: dbFolderPath as String, withIntermediateDirectories: true)
        }

        let dbPath = dbFolderPath.appendingPathComponent("podcast_testDB.sqlite3")
        if FileManager.default.fileExists(atPath: dbPath) {
            try FileManager.default.removeItem(atPath: dbPath)
        }
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE
        let dbQueue = try XCTUnwrap(FMDatabaseQueue(path: dbPath, flags: flags))
        return DataManager(dbQueue: dbQueue)
    }

    /// Tests migrating from values stored in `SJPodcast` properties to `SJPodcast.settings`
    func testValueMigration() throws {
        dataManager.importPodcastSettings()

        let podcasts = dataManager.allPodcasts(includeUnsubscribed: true)
        let podcast = try XCTUnwrap(podcasts.first)

        XCTAssertEqual(newOverrideGlobalEffects, podcast.settings.customEffects, "Value of customEffects should change after import")
        XCTAssertEqual(newAutoStartFrom, podcast.settings.autoStartFrom, "Value of autoStartFrom should change after import")
        XCTAssertEqual(newAutoSkipLast, podcast.settings.autoSkipLast, "Value of autoSkipLast should change after import")
        XCTAssertEqual(TrimSilence(amount: newTrimSilence).rawValue, podcast.settings.trimSilence.rawValue, "Value of trimSilence should change after import")
        XCTAssertEqual(newBoostVolume, podcast.settings.boostVolume, "Value of boostVolume should change after import")
        XCTAssertEqual(newPlaybackSpeed, podcast.settings.playbackSpeed, "Value of playbackSpeed should change after import")
        XCTAssertEqual(newPushEnabled, podcast.settings.notification, "Value of notification should change after import")
        XCTAssertEqual(newOverrideGlobalArchive, podcast.settings.autoArchive, "Value of autoArchive should change after import")
        XCTAssertEqual(AutoArchiveAfterPlayed(time: newArchivePlayedAfter), podcast.settings.autoArchivePlayed, "Value of autoArchivePlayed should change after import")
        XCTAssertEqual(AutoArchiveAfterInactive(time: newArchiveInactiveAfter), podcast.settings.autoArchiveInactive, "Value of autoArchiveInactive should change after import")
        XCTAssertEqual(newArchiveEpisodeLimit, podcast.settings.autoArchiveEpisodeLimit, "Value of autoArchiveEpisodeLimit should change after import")
        XCTAssertEqual(newUpNextPosition, podcast.settings.autoUpNextSetting, "Value of addToUpNextPosition should change after import")
        XCTAssertEqual(newUpNextPosition != .off, podcast.settings.addToUpNext, "Value of addToUpNext should change after import")
        XCTAssertEqual(newUpNextPosition, podcast.settings.autoUpNextSetting, "Value of addToUpNextPosition should change after import")
        XCTAssertEqual(PodcastEpisodeSortOrder(old: newEpisodeSortOrder), podcast.settings.episodesSortOrder, "Value of episodesSortOrder should change after import")
        XCTAssertEqual(newEpisodeGrouping, podcast.settings.episodeGrouping, "Value of autoArchiveInactive should change after import")
        XCTAssertEqual(newShowArchive, podcast.settings.showArchived, "Value of showArchived should change after import")
        XCTAssertNotNil(podcast.settings.$showArchived.modifiedAt)
    }

    /// Tests that the default values are used when a value is missing from the JSON (such as when a key was added after writing the JSON object)
    func testDefaultValuesWhenMissing() throws {
        let json = "{ \"autoArchive\": { \"value\": true, \"modifiedDate\": \"2024-03-28T13:49:51.141Z\"} }"
        let settings = try JSONDecoder().decode(PodcastSettings.self, from: json.data(using: .utf8)!)

        XCTAssertTrue(settings.autoArchive, "Should contain new value from JSON")
        XCTAssertEqual(settings.autoArchivePlayed, .afterPlaying, "Should contain default value")
        XCTAssertEqual(settings.playbackSpeed, 1, "Should contain default value")
    }


    func testImportPerformance() throws {
        featureFlagMock.set(.newSettingsStorage, value: false)

        let dataManager = try setupDatabase()
        let newUpNextSetting = AutoAddToUpNextSetting.addFirst

        let podcastCount = 500
        (0...podcastCount).forEach { _ in
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString
            podcast.addedDate = Date()
            podcast.setAutoAddToUpNext(setting: newUpNextSetting)

            dataManager.save(podcast: podcast)
        }

        self.measure {
            dataManager.importPodcastSettings()
        }

        featureFlagMock.reset()
    }
}
