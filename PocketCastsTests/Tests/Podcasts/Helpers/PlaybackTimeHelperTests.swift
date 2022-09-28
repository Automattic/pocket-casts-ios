import XCTest

@testable import PocketCastsDataModel
@testable import podcasts

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

        XCTAssertEqual(playbackTime, 12.minutes)
    }
}
