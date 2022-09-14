import XCTest

@testable import podcasts
@testable import PocketCastsDataModel

class PlaybackTimeHelperTests: XCTestCase {
    func testLastSevenDaysPlaytimeWhenNothingIsReturned() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = []

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInMinutes()

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

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInMinutes()

        XCTAssertEqual(playbackTime, 2)
    }

    func testLastSevenDaysPlaytimeWhenPlayedMultipleEpisodes() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = [
            // These episodes were played in the last 7 days
            EpisodeBuilder()
                .with(playedUpTo: 120)
                .with(lastPlaybackInteractionDate: Date())
                .build(),

            EpisodeBuilder()
                .with(playedUpTo: 1200)
                .with(lastPlaybackInteractionDate: Date().addingTimeInterval(-5000))
                .build(),

            // This was played a month ago

            EpisodeBuilder()
                .with(playedUpTo: 1200)
                .with(lastPlaybackInteractionDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
                .build()
        ]

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInMinutes()

        XCTAssertEqual(playbackTime, 22)
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
