import XCTest

@testable import podcasts
@testable import PocketCastsDataModel

class EndOfYearStoriesBuilderTests: XCTestCase {
    func testReturnListeningTimeStoryIfBiggerThanZero() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listeningTimeToReturn = 3000
        let stories = await builder.build()

        XCTAssertTrue(stories.0.contains(.listeningTime))
        XCTAssertEqual(stories.1.listeningTime, 3000)
    }

    func testDontReturnListeningTimeStoryIfZero() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listeningTimeToReturn = 0
        let stories = await builder.build()

        XCTAssertFalse(stories.0.contains(.listeningTime))
        XCTAssertEqual(stories.1.listeningTime, 0)
    }

    func testReturnListenedCategories() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listenedCategoriesToReturn = [
            ListenedCategory(numberOfPodcasts: 1, categoryTitle: "title", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 500)
        ]
        let stories = await builder.build()

        XCTAssertEqual(stories.0.first, EndOfYearStory.listenedCategories)
        XCTAssertEqual(stories.0[1], EndOfYearStory.topCategories)
        XCTAssertEqual(stories.1.listenedCategories.first?.numberOfPodcasts, 1)
        XCTAssertEqual(stories.1.listenedCategories.first?.numberOfPodcasts, 1)
    }

    func testDontReturnListenedCategoriesIfEmpty() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listenedCategoriesToReturn = []
        let stories = await builder.build()

        XCTAssertFalse(stories.0.contains(.listenedCategories))
        XCTAssertFalse(stories.0.contains(.topCategories))
        XCTAssertTrue(stories.1.listenedCategories.isEmpty)
    }

    func testReturnListenedPodcastsAndEpisodes() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listenedNumbersToReturn = ListenedNumbers(numberOfPodcasts: 3, numberOfEpisodes: 10)
        let stories = await builder.build()

        XCTAssertEqual(stories.0.first, EndOfYearStory.numberOfPodcastsAndEpisodesListened)
        XCTAssertEqual(stories.1.listenedNumbers.numberOfPodcasts, 3)
        XCTAssertEqual(stories.1.listenedNumbers.numberOfEpisodes, 10)
    }

    func testDontReturnListenedPodcastsAndEpisodes() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listenedNumbersToReturn = ListenedNumbers(numberOfPodcasts: 0, numberOfEpisodes: 0)
        let stories = await builder.build()

        XCTAssertFalse(stories.0.contains(.numberOfPodcastsAndEpisodesListened))
        XCTAssertNil(stories.1.listenedNumbers)
    }

    func testReturnTopOnePodcast() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.topPodcastsToReturn = [
            TopPodcast(podcast: Podcast.previewPodcast(),
                       numberOfPlayedEpisodes: 3,
                       totalPlayedTime: 3000)
        ]
        let stories = await builder.build()

        XCTAssertEqual(stories.0.first, EndOfYearStory.topOnePodcast)
        XCTAssertEqual(stories.1.topPodcasts.count, 1)
        XCTAssertNotNil(stories.1.topPodcasts.first?.podcast)
        XCTAssertEqual(stories.1.topPodcasts.first?.numberOfPlayedEpisodes, 3)
        XCTAssertEqual(stories.1.topPodcasts.first?.totalPlayedTime, 3000)
    }

    func testDontReturnTopOnePodcast() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.topPodcastsToReturn = []
        let stories = await builder.build()

        XCTAssertFalse(stories.0.contains(.topOnePodcast))
        XCTAssertEqual(stories.1.topPodcasts.count, 0)
    }

    func testReturnTopFivePodcasts() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.topPodcastsToReturn = [
            TopPodcast(podcast: Podcast.previewPodcast(),
                       numberOfPlayedEpisodes: 3,
                       totalPlayedTime: 3000),
            TopPodcast(podcast: Podcast.previewPodcast(),
                       numberOfPlayedEpisodes: 10,
                       totalPlayedTime: 4000)
        ]
        let stories = await builder.build()

        XCTAssertEqual(stories.0[1], EndOfYearStory.topFivePodcasts)
        XCTAssertEqual(stories.1.topPodcasts.count, 2)
    }

    func testReturnLongestEpisode() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        let episode = EpisodeMock()
        endOfYearManager.longestEpisodeToReturn = episode
        let stories = await builder.build()

        XCTAssertEqual(stories.0.first, EndOfYearStory.longestEpisode)
        XCTAssertNotNil(stories.1.longestEpisode)
        XCTAssertNotNil(stories.1.longestEpisodePodcast)
    }

    func testDontReturnLongestEpisode() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.longestEpisodeToReturn = nil
        let stories = await builder.build()

        XCTAssertFalse(stories.0.contains(.longestEpisode))
        XCTAssertNil(stories.1.longestEpisode)
        XCTAssertNil(stories.1.longestEpisodePodcast)
    }

    func testSyncWhenNeeded() async {
        var syncCalled = false
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, sync: { syncCalled = true })

        endOfYearManager.isFullListeningHistoryToReturn = false
        let stories = await builder.build()

        XCTAssertTrue(syncCalled)
    }

    func testDontSyncWhenNotNeeded() async {
        var syncCalled = false
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager, sync: { syncCalled = true })

        endOfYearManager.isFullListeningHistoryToReturn = true
        let stories = await builder.build()

        XCTAssertFalse(syncCalled)
    }
}

private class EpisodeMock: Episode {
    override func parentPodcast() -> Podcast? {
        return Podcast.previewPodcast()
    }
}
