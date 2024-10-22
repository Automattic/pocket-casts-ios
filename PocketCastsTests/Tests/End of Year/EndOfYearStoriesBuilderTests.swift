import XCTest

@testable import podcasts
@testable import PocketCastsDataModel
@testable import PocketCastsServer

class EndOfYearStoriesBuilderTests: XCTestCase {
    override func setUp() {
        // Do not sync for episodes
        Settings.setHasSyncedEpisodesForPlayback(true, year: 2023)

        // Pretend we're logged in
        ServerSettings.setSyncingEmail(email: "test@test.com")
    }

    func testReturnListeningTimeStoryIfBiggerThanZero() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.topPodcastsToReturn = [
            TopPodcast(podcast: Podcast.previewPodcast(),
                       numberOfPlayedEpisodes: 3,
                       totalPlayedTime: 3000)
        ]
        endOfYearManager.listeningTimeToReturn = 3000
        await builder.build()

        XCTAssertTrue(model.stories.contains(.listeningTime))
        XCTAssertEqual(model.data.listeningTime, 3000)
    }

    func testDontReturnListeningTimeStoryIfZero() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.listeningTimeToReturn = 0
        await builder.build()

        XCTAssertFalse(model.stories.contains(.listeningTime))
        XCTAssertEqual(model.data.listeningTime, 0)
    }

    func testReturnListenedCategories() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.listenedCategoriesToReturn = [
            ListenedCategory(numberOfPodcasts: 1, categoryTitle: "title", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 500, numberOfEpisodes: 5)
        ]
        await builder.build()

        XCTAssertEqual(model.stories.first, EndOfYear2023Story.topCategories)
        XCTAssertEqual(model.data.listenedCategories.first?.numberOfPodcasts, 1)
        XCTAssertEqual(model.data.listenedCategories.first?.totalPlayedTime, 500)
        XCTAssertEqual(model.data.listenedCategories.first?.numberOfEpisodes, 5)
    }

    func testDontReturnListenedCategoriesIfEmpty() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.listenedCategoriesToReturn = []
        await builder.build()

        XCTAssertFalse(model.stories.contains(.topCategories))
        XCTAssertTrue(model.data.listenedCategories.isEmpty)
    }

    func testReturnListenedPodcastsAndEpisodes() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.topPodcastsToReturn = [
            TopPodcast(podcast: Podcast.previewPodcast(),
                       numberOfPlayedEpisodes: 3,
                       totalPlayedTime: 3000)
        ]
        endOfYearManager.listenedNumbersToReturn = ListenedNumbers(numberOfPodcasts: 3, numberOfEpisodes: 10)
        await builder.build()

        XCTAssertEqual(model.stories.first, EndOfYear2023Story.numberOfPodcastsAndEpisodesListened)
        XCTAssertEqual(model.data.listenedNumbers.numberOfPodcasts, 3)
        XCTAssertEqual(model.data.listenedNumbers.numberOfEpisodes, 10)
    }

    func testDontReturnListenedPodcastsAndEpisodes() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.listenedNumbersToReturn = ListenedNumbers(numberOfPodcasts: 0, numberOfEpisodes: 0)
        await builder.build()

        XCTAssertFalse(model.stories.contains(.numberOfPodcastsAndEpisodesListened))
        XCTAssertNil(model.data.listenedNumbers)
    }

    func testReturnTopOnePodcast() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.topPodcastsToReturn = [
            TopPodcast(podcast: Podcast.previewPodcast(),
                       numberOfPlayedEpisodes: 3,
                       totalPlayedTime: 3000)
        ]
        await builder.build()

        XCTAssertEqual(model.stories.first, EndOfYear2023Story.topOnePodcast)
        XCTAssertEqual(model.data.topPodcasts.count, 1)
        XCTAssertNotNil(model.data.topPodcasts.first?.podcast)
        XCTAssertEqual(model.data.topPodcasts.first?.numberOfPlayedEpisodes, 3)
        XCTAssertEqual(model.data.topPodcasts.first?.totalPlayedTime, 3000)
    }

    func testDontReturnTopOnePodcast() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.topPodcastsToReturn = []
        let stories = await builder.build()

        XCTAssertFalse(model.stories.contains(.topOnePodcast))
        XCTAssertEqual(model.data.topPodcasts.count, 0)
    }

    func testReturnTopFivePodcasts() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.topPodcastsToReturn = [
            TopPodcast(podcast: Podcast.previewPodcast(),
                       numberOfPlayedEpisodes: 3,
                       totalPlayedTime: 3000),
            TopPodcast(podcast: Podcast.previewPodcast(),
                       numberOfPlayedEpisodes: 10,
                       totalPlayedTime: 4000)
        ]
        await builder.build()

        XCTAssertEqual(model.stories[1], EndOfYear2023Story.topFivePodcasts)
        XCTAssertEqual(model.data.topPodcasts.count, 2)
    }

    func testReturnLongestEpisode() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        let episode = EpisodeMock()
        endOfYearManager.longestEpisodeToReturn = episode
        await builder.build()

        XCTAssertEqual(model.stories.first, EndOfYear2023Story.longestEpisode)
        XCTAssertNotNil(model.data.longestEpisode)
        XCTAssertNotNil(model.data.longestEpisodePodcast)
    }

    func testDontReturnLongestEpisode() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.longestEpisodeToReturn = nil
        await builder.build()

        XCTAssertFalse(model.stories.contains(.longestEpisode))
        XCTAssertNil(model.data.longestEpisode)
        XCTAssertNil(model.data.longestEpisodePodcast)
    }

    func testReturnYearOverYearListeningTime() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.yearOverYearToReturn = YearOverYearListeningTime(
            totalPlayedTimeThisYear: 153,
            totalPlayedTimeLastYear: 100
        )

        await builder.build()

        XCTAssertTrue(model.stories.contains(.yearOverYearListeningTime))
        XCTAssertEqual(endOfYearManager.yearOverYearToReturn?.percentage, 53.0)
        XCTAssertNotNil(model.data.yearOverYearListeningTime)
    }

    func testReturnCompletionRate() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model)

        endOfYearManager.episodesStartedAndCompleted = EpisodesStartedAndCompleted(
            started: 10,
            completed: 5
        )

        await builder.build()

        XCTAssertTrue(model.stories.contains(.completionRate))
        XCTAssertEqual(endOfYearManager.episodesStartedAndCompleted?.percentage, 0.5)
        XCTAssertNotNil(model.data.episodesStartedAndCompleted)
    }

    func testSyncWhenNeeded() async {
        var syncCalled = false
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model, sync: { syncCalled = true; return true })
        Settings.setHasSyncedEpisodesForPlayback(true, year: 2023)

        endOfYearManager.isFullListeningHistoryToReturn = false
        _ = await builder.build()

        XCTAssertTrue(syncCalled)
    }

    func testDontSyncWhenAlreadySynced() async {
        var syncCalled = false
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model, sync: { syncCalled = true; return true })
        Settings.setHasSyncedEpisodesForPlayback(true, year: 2023)

        endOfYearManager.isFullListeningHistoryToReturn = false
        _ = await builder.build()

        XCTAssertFalse(syncCalled)
    }

    /// When a user syncs their listening history but aren't Plus users
    /// the app doesn't sync their 2022 data.
    /// So if they become Plus we should re-sync again.
    func testSyncWhenAlreadySyncedButAsFreeUser() async {
        var syncCalledTimes = 0
        var plusUser = false
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model, sync: { syncCalledTimes += 1; return true }, hasActiveSubscription: { plusUser })
        Settings.setHasSyncedEpisodesForPlayback(false, year: 2023)
        endOfYearManager.isFullListeningHistoryToReturn = false
        _ = await builder.build()

        plusUser = true
        _ = await builder.build()

        XCTAssertEqual(syncCalledTimes, 2)
    }

    func testDontSyncAgainWhenSubscriptionStatusDontChange() async {
        var syncCalledTimes = 0
        let plusUser = false
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let model = EndOfYear2023StoriesModel()
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, model: model, sync: { syncCalledTimes += 1; return true }, hasActiveSubscription: { plusUser })
        Settings.setHasSyncedEpisodesForPlayback(false, year: 2023)
        endOfYearManager.isFullListeningHistoryToReturn = false
        _ = await builder.build()

        _ = await builder.build()

        XCTAssertEqual(syncCalledTimes, 1)
    }
}

private class EpisodeMock: Episode {
    override func parentPodcast(dataManager: DataManager) -> Podcast? {
        return Podcast.previewPodcast()
    }
}
