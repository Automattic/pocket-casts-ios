import XCTest
import Foundation
import PocketCastsUtils
@testable import podcasts
import PocketCastsDataModel

class AppSettingsImportUserDefaultsTests: XCTestCase {
    private let newBoostVolume = true
    private let newTrimSilence = TrimSilenceAmount.medium

    let dataManager = DataManagerMock()

    override func setUp() {
        super.setUp()
        let podcast = Podcast()
        podcast.boostVolume = newBoostVolume
        podcast.trimSilenceAmount = newTrimSilence.rawValue
        dataManager.podcastsToReturn = [podcast]
    }

    /// Tests migrating from values stored in `SJPodcast` properties to `SJPodcast.settings`
    func testValueMigration() throws {
        dataManager.importPodcastSettings()

        let podcasts = dataManager.allPodcasts(includeUnsubscribed: true)
        let podcast = try XCTUnwrap(podcasts.first)

        XCTAssertEqual(newBoostVolume, podcast.settings.boostVolume, "Value of boostVolume should change after import")
        XCTAssertEqual(TrimSilence(amount: newTrimSilence).rawValue, podcast.settings.trimSilence.rawValue, "Value of trimSilence should change after import")
    }
}
