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
                .with(playedUpTo: 2.minutes)
                .with(lastPlaybackInteractionDate: Date().addingTimeInterval(-1.minutes))
                .build()
        ]

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInMinutes()

        XCTAssertEqual(playbackTime, 2.minutes)
    }

    func testLastSevenDaysPlaytimeWhenPlayedMultipleEpisodes() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = [
            // These episodes were played in the last 7 days
            EpisodeBuilder()
                .with(playedUpTo: 2.minutes)
                .with(lastPlaybackInteractionDate: Date().addingTimeInterval(-1.minutes))
                .build(),

            EpisodeBuilder()
                .with(playedUpTo: 10.minutes)
                .with(lastPlaybackInteractionDate: Date().addingTimeInterval(-2.minutes))
                .build(),

            // This was played a month ago

            EpisodeBuilder()
                .with(playedUpTo: 10.minutes)
                .with(lastPlaybackInteractionDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
                .build()
        ]

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInMinutes()

        XCTAssertEqual(playbackTime, 22.minutes)
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

public extension Double {
    var minutes: TimeInterval {
        self * 60
    }
}
