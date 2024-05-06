import XCTest
import Foundation
import PocketCastsUtils
@testable import podcasts
import PocketCastsDataModel

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

    let dataManager = DataManagerMock()

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
    }
}
