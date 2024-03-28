import XCTest
import Foundation
import PocketCastsUtils
@testable import podcasts
import PocketCastsDataModel

class PodcastSettingsImportUserDefaultsTests: XCTestCase {
    private let newBoostVolume = true
    private let newTrimSilence = TrimSilenceAmount.medium
    private let newArchivePlayedAfter = AutoArchiveAfterTime.after1Week
    private let newArchiveInactiveAfter = AutoArchiveAfterTime.after90Days
    private let newUpNextPosition = AutoAddToUpNextSetting.addLast
    private let newEpisodeSortOrder = PodcastEpisodeSortOrder.Old.oldestToNewest
    private let newEpisodeGrouping = PodcastGrouping.starred

    let dataManager = DataManagerMock()

    override func setUp() {
        super.setUp()
        let podcast = Podcast()
        podcast.trimSilenceAmount = newTrimSilence.rawValue
        podcast.boostVolume = newBoostVolume
        podcast.autoArchivePlayedAfter = newArchivePlayedAfter.rawValue
        podcast.autoArchiveInactiveAfter = newArchiveInactiveAfter.rawValue
        podcast.autoAddToUpNext = newUpNextPosition.rawValue
        podcast.episodeSortOrder = newEpisodeSortOrder.rawValue
        podcast.episodeGrouping = newEpisodeGrouping.rawValue
        dataManager.podcastsToReturn = [podcast]
    }

    /// Tests migrating from values stored in `SJPodcast` properties to `SJPodcast.settings`
    func testValueMigration() throws {
        dataManager.importPodcastSettings()

        let podcasts = dataManager.allPodcasts(includeUnsubscribed: true)
        let podcast = try XCTUnwrap(podcasts.first)

        XCTAssertEqual(TrimSilence(amount: newTrimSilence).rawValue, podcast.settings.trimSilence.rawValue, "Value of trimSilence should change after import")
        XCTAssertEqual(newBoostVolume, podcast.settings.boostVolume, "Value of boostVolume should change after import")
        XCTAssertEqual(AutoArchiveAfterPlayed(time: newArchivePlayedAfter), podcast.settings.autoArchivePlayed, "Value of autoArchivePlayed should change after import")
        XCTAssertEqual(AutoArchiveAfterInactive(time: newArchiveInactiveAfter), podcast.settings.autoArchiveInactive, "Value of autoArchiveInactive should change after import")
        XCTAssertEqual(newUpNextPosition, podcast.settings.autoUpNextSetting, "Value of addToUpNextPosition should change after import")
        XCTAssertEqual(PodcastEpisodeSortOrder(old: newEpisodeSortOrder), podcast.settings.episodesSortOrder, "Value of episodesSortOrder should change after import")
        XCTAssertEqual(newEpisodeGrouping, podcast.settings.episodeGrouping, "Value of autoArchiveInactive should change after import")
    }
}
