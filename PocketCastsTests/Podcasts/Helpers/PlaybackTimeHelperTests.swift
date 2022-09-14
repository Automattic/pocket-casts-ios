import XCTest

@testable import podcasts
@testable import PocketCastsDataModel

class PlaybackTimeHelperTests: XCTestCase {
    func testLastSevenDaysPlaytimeWhenNothingIsReturned() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = []

        let playbackTime = playbackTimeHelper.playedUpToSumInLastSevenDays()

        XCTAssertEqual(playbackTime, 0)
    }

    func testLastSevenDaysPlaytimeWhenPlayedASingleEpisode() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = [
            EpisodeBuilder()
                .with(playedUpTo: 2.minutes)
                .with(lastPlaybackInteractionDate: .yesterday)
                .build()
        ]

        let playbackTime = playbackTimeHelper.playedUpToSumInLastSevenDays()

        XCTAssertEqual(playbackTime, 2.minutes)
    }

    func testLastSevenDaysPlaytimeWhenPlayedMultipleEpisodes() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = [
            // These episodes were played in the last 7 days
            EpisodeBuilder()
                .with(playedUpTo: 2.minutes)
                .with(lastPlaybackInteractionDate: .yesterday)
                .build(),

            EpisodeBuilder()
                .with(playedUpTo: 10.minutes)
                .with(lastPlaybackInteractionDate: .yesterday)
                .build(),

            // This was played a month ago
            EpisodeBuilder()
                .with(playedUpTo: 10.minutes)
                .with(lastPlaybackInteractionDate: .lastMonth)
                .build()
        ]

        let playbackTime = playbackTimeHelper.playedUpToSumInLastSevenDays()

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

extension Date {
    static var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }

    static var lastMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    }
}
