import XCTest

@testable import podcasts
@testable import PocketCastsDataModel

class PlaybackTimeHelperTests: XCTestCase {
    func testLastSevenDaysPlaytimeWhenNothingIsReturned() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = []

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInSeconds()

        XCTAssertEqual(playbackTime, 0)
    }

    func testLastSevenDaysPlaytimeWhenPlayedASingleEpisode() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = [
            EpisodeBuilder()
                .with(playedUpTo: 120)
                .with(lastPlaybackInteractionDate: Date())
                .build()
        ]

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInSeconds()

        XCTAssertEqual(playbackTime, 2)
    }
}

class DataManagerMock: DataManager {
    var episodesToReturn: [Episode] = []

    override func findEpisodesWhere(customWhere: String, arguments: [Any]?) -> [Episode] {
        return episodesToReturn
    }
}

class EpisodeBuilder {
    var episode = Episode()

    func with(playedUpTo: Double) -> Self {
        episode.playedUpTo = playedUpTo
        return self
    }

    func with(lastPlaybackInteractionDate: Date) -> Self {
        episode.lastPlaybackInteractionDate = lastPlaybackInteractionDate
        return self
    }

    func build() -> Episode {
        episode
    }
}
