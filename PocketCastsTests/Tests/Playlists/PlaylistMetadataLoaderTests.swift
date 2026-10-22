import XCTest
@testable import PocketCastsDataModel
@testable import podcasts

final class PlaylistMetadataLoaderTests: DBTestCase {
    func testLoadCountUsesTheRulesOfTheLatestRequest() async {
        podcast.subscribed = 1
        dataManager.save(podcast: podcast)
        let loader = PlaylistMetadataLoader(dataManager: dataManager)

        let playlistBeforeEdit = EpisodeFilter.makeDefault()
        playlistBeforeEdit.playlistName = "Smart"
        playlistBeforeEdit.playlistUpdateDate = Date(timeIntervalSince1970: 1_000)

        let playlistAfterEdit = EpisodeFilter.makeDefault()
        playlistAfterEdit.uuid = playlistBeforeEdit.uuid
        playlistAfterEdit.playlistName = "Smart"
        playlistAfterEdit.filterStarred = true
        playlistAfterEdit.playlistUpdateDate = Date(timeIntervalSince1970: 2_000)

        async let countBeforeEdit = loader.loadCount(for: playlistBeforeEdit)
        async let countAfterEdit = loader.loadCount(for: playlistAfterEdit)
        let (before, after) = await (countBeforeEdit, countAfterEdit)

        XCTAssertEqual(before, 1)
        XCTAssertEqual(after, 0)
    }
}
