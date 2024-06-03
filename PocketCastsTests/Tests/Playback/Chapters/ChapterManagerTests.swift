import XCTest

@testable import podcasts
@testable import PocketCastsDataModel
@testable import PocketCastsServer
@testable import PocketCastsUtils

class ChapterManagerTests: XCTestCase {
    let featureFlagMock = FeatureFlagMock()
    var previousSubscriptionPaidStatus: Int!
    var previousSubscriptionTier: SubscriptionTier!

    override func setUp() {
        previousSubscriptionPaidStatus = SubscriptionHelper.hasActiveSubscription() ? 1 : 0
        previousSubscriptionTier = SubscriptionHelper.subscriptionTier
        SubscriptionHelper.setSubscriptionPaid(1)
        SubscriptionHelper.subscriptionTier = .patron
    }

    override func tearDown() {
        featureFlagMock.reset()
        SubscriptionHelper.setSubscriptionPaid(previousSubscriptionPaidStatus)
        SubscriptionHelper.subscriptionTier = previousSubscriptionTier
    }

    /// Update the current chapter given a TimeInterval
    func testUpdateCurrentChapterBasedOnTime() async {
        featureFlagMock.set(.deselectChapters, value: true)
        let parserMock = PodcastChapterParserMock()
        let showInfoCoordinatorMock = ShowInfoCoordinatorMock()
        parserMock.chapters = [
            chapterInfo(startTime: 0, duration: 100, shouldPlay: true),
            chapterInfo(startTime: 101, duration: 200, shouldPlay: false),
            chapterInfo(startTime: 201, duration: 300, shouldPlay: true),
            chapterInfo(startTime: 301, duration: 400, shouldPlay: false),
            chapterInfo(startTime: 401, duration: 500, shouldPlay: true),
            chapterInfo(startTime: 501, duration: 600, shouldPlay: false)
        ]
        let chapterManager = ChapterManager(chapterParser: parserMock, showInfoCoordinator: showInfoCoordinatorMock)
        await chapterManager.parseChapters(episode: EpisodeMock(), duration: 600)

        chapterManager.updateCurrentChapter(time: 10)

        XCTAssertEqual(chapterManager.currentChapters.visibleChapter, chapterInfo(startTime: 0, duration: 100, shouldPlay: true))
    }

    /// Update the current chapter given a TimeInterval
    func testReturnNextVisiblePlayableChapter() async {
        featureFlagMock.set(.deselectChapters, value: true)
        let showInfoCoordinatorMock = ShowInfoCoordinatorMock()
        let parserMock = PodcastChapterParserMock()
        parserMock.chapters = [
            chapterInfo(startTime: 0, duration: 100, shouldPlay: true),
            chapterInfo(startTime: 101, duration: 200, shouldPlay: false),
            chapterInfo(startTime: 201, duration: 300, shouldPlay: true),
            chapterInfo(startTime: 301, duration: 400, shouldPlay: false),
            chapterInfo(startTime: 401, duration: 500, shouldPlay: true),
            chapterInfo(startTime: 501, duration: 600, shouldPlay: false)
        ]
        let chapterManager = ChapterManager(chapterParser: parserMock, showInfoCoordinator: showInfoCoordinatorMock)
        await chapterManager.parseChapters(episode: EpisodeMock(), duration: 600)
        chapterManager.updateCurrentChapter(time: 10)

        let nextVisiblePlayableChapter = chapterManager.nextVisiblePlayableChapter()

        XCTAssertEqual(nextVisiblePlayableChapter, chapterInfo(startTime: 201, duration: 300, shouldPlay: true))
    }

    /// Update the current chapter given a TimeInterval
    func testReturnPreviousVisiblePlayableChapter() async {
        featureFlagMock.set(.deselectChapters, value: true)
        let showInfoCoordinatorMock = ShowInfoCoordinatorMock()
        let parserMock = PodcastChapterParserMock()
        parserMock.chapters = [
            chapterInfo(startTime: 0, duration: 100, shouldPlay: true),
            chapterInfo(startTime: 101, duration: 200, shouldPlay: false),
            chapterInfo(startTime: 201, duration: 300, shouldPlay: true),
            chapterInfo(startTime: 301, duration: 400, shouldPlay: false),
            chapterInfo(startTime: 401, duration: 500, shouldPlay: true),
            chapterInfo(startTime: 501, duration: 600, shouldPlay: false)
        ]
        let chapterManager = ChapterManager(chapterParser: parserMock, showInfoCoordinator: showInfoCoordinatorMock)
        await chapterManager.parseChapters(episode: EpisodeMock(), duration: 600)
        chapterManager.updateCurrentChapter(time: 450)

        let nextVisiblePlayableChapter = chapterManager.previousVisibleChapter()

        XCTAssertEqual(nextVisiblePlayableChapter, chapterInfo(startTime: 201, duration: 300, shouldPlay: true))
    }

    /// If the Feature Flag is false then everything should be played
    func testEverythingShouldPlay() async {
        featureFlagMock.set(.deselectChapters, value: false)
        let showInfoCoordinatorMock = ShowInfoCoordinatorMock()
        let parserMock = PodcastChapterParserMock()
        parserMock.chapters = [
            chapterInfo(startTime: 0, duration: 100, shouldPlay: true),
            chapterInfo(startTime: 101, duration: 200, shouldPlay: false),
            chapterInfo(startTime: 201, duration: 300, shouldPlay: true),
            chapterInfo(startTime: 301, duration: 400, shouldPlay: false),
            chapterInfo(startTime: 401, duration: 500, shouldPlay: true),
            chapterInfo(startTime: 501, duration: 600, shouldPlay: false)
        ]
        let chapterManager = ChapterManager(chapterParser: parserMock, showInfoCoordinator: showInfoCoordinatorMock)
        await chapterManager.parseChapters(episode: EpisodeMock(), duration: 600)
        chapterManager.updateCurrentChapter(time: 450)

        XCTAssertEqual(chapterManager.playableChapterCount(), 6)
    }

    func chapterInfo(startTime: TimeInterval, duration: TimeInterval, shouldPlay: Bool) -> ChapterInfo {
        let chapterInfo = ChapterInfo()
        chapterInfo.shouldPlay = shouldPlay
        chapterInfo.startTime = CMTime(seconds: startTime, preferredTimescale: .max)
        chapterInfo.duration = duration
        return chapterInfo
    }
}

class PodcastChapterParserMock: PodcastChapterParser {
    var chapters: [ChapterInfo] = []

    override func parseRemoteFile(_ remoteUrl: String, episodeDuration: TimeInterval, completion: @escaping (([ChapterInfo]) -> Void)) {
        completion(chapters)
    }

    override func parseRemoteFile(_ remoteUrl: String, episodeDuration: TimeInterval) async -> [ChapterInfo] {
        chapters
    }
}

private class ShowInfoCoordinatorMock: ShowInfoCoordinating {
    func loadShowNotes(podcastUuid: String, episodeUuid: String) async throws -> String {
        ""
    }

    func loadEpisodeArtworkUrl(podcastUuid: String, episodeUuid: String) async throws -> String? {
        nil
    }

    func loadChapters(podcastUuid: String, episodeUuid: String) async throws -> ([PocketCastsDataModel.Episode.Metadata.EpisodeChapter]?, [podcasts.PodcastIndexChapter]?) {
        (nil, nil)
    }
}

private class EpisodeMock: Episode {
    override var downloadUrl: String? {
        get { "https://pocketcasts.com/" }
        set {}
    }
}
