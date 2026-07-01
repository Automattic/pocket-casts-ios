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

    /// Generated chapters are timed against the reference (clean) audio; when a
    /// fingerprint mapping is available their start times should be re-mapped onto
    /// the played file's timeline (here a flat +30s dynamic-ad shift).
    func testGeneratedChaptersAreRemappedToPlaybackTimeline() async {
        let parserMock = PodcastChapterParserMock() // no file chapters -> falls through to generated
        let showInfoCoordinatorMock = GeneratedChaptersShowInfoCoordinatorMock(generatedChapters: [
            GeneratedChapter(title: "One", timestamp: "00:00", startTime: 0),
            GeneratedChapter(title: "Two", timestamp: "01:40", startTime: 100),
            GeneratedChapter(title: "Three", timestamp: "03:20", startTime: 200)
        ])
        let mapper = ChapterReferenceTimeMappingMock(offset: 30, hasMapping: true)
        ChapterReferenceTimeMappingProvider.current = mapper
        defer { ChapterReferenceTimeMappingProvider.current = nil }

        let chapterManager = ChapterManager(chapterParser: parserMock, showInfoCoordinator: showInfoCoordinatorMock)
        await chapterManager.parseChapters(episode: EpisodeMock(), duration: 300)

        XCTAssertEqual(chapterManager.chapterAt(index: 0)?.startTime.seconds ?? -1, 30, accuracy: 0.01)
        XCTAssertEqual(chapterManager.chapterAt(index: 1)?.startTime.seconds ?? -1, 130, accuracy: 0.01)
        XCTAssertEqual(chapterManager.chapterAt(index: 2)?.startTime.seconds ?? -1, 230, accuracy: 0.01)
        // Durations are recomputed from the adjusted start times; the last runs to the episode end.
        XCTAssertEqual(chapterManager.chapterAt(index: 0)?.duration ?? -1, 100, accuracy: 0.01)
        XCTAssertEqual(chapterManager.chapterAt(index: 2)?.duration ?? -1, 70, accuracy: 0.01)
    }

    /// Without a usable mapping the generated chapters keep their reference times.
    func testGeneratedChaptersKeepReferenceTimeWhenMappingUnavailable() async {
        let parserMock = PodcastChapterParserMock()
        let showInfoCoordinatorMock = GeneratedChaptersShowInfoCoordinatorMock(generatedChapters: [
            GeneratedChapter(title: "One", timestamp: "00:00", startTime: 0),
            GeneratedChapter(title: "Two", timestamp: "01:40", startTime: 100)
        ])
        // Mapping present but not yet active -> must be treated as unavailable.
        let mapper = ChapterReferenceTimeMappingMock(offset: 30, hasMapping: false)
        ChapterReferenceTimeMappingProvider.current = mapper
        defer { ChapterReferenceTimeMappingProvider.current = nil }

        let chapterManager = ChapterManager(chapterParser: parserMock, showInfoCoordinator: showInfoCoordinatorMock)
        await chapterManager.parseChapters(episode: EpisodeMock(), duration: 300)

        XCTAssertEqual(chapterManager.chapterAt(index: 0)?.startTime.seconds ?? -1, 0, accuracy: 0.01)
        XCTAssertEqual(chapterManager.chapterAt(index: 1)?.startTime.seconds ?? -1, 100, accuracy: 0.01)
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

    func loadEpisodeArtworkUrl(podcastUuid: String, episodeUuid: String) async throws -> URL? {
        nil
    }

    func loadChapters(podcastUuid: String, episodeUuid: String) async throws -> ([PocketCastsDataModel.Episode.Metadata.EpisodeChapter]?, [podcasts.PodcastIndexChapter]?, [GeneratedChapter]?) {
        (nil, nil, nil)
    }

    func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
        return (transcripts: [], hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
    }
}

private class EpisodeMock: Episode {
    override var downloadUrl: String? {
        get { "https://pocketcasts.com/" }
        set {}
    }
}

private class GeneratedChaptersShowInfoCoordinatorMock: ShowInfoCoordinating {
    let generatedChapters: [GeneratedChapter]

    init(generatedChapters: [GeneratedChapter]) {
        self.generatedChapters = generatedChapters
    }

    func loadShowNotes(podcastUuid: String, episodeUuid: String) async throws -> String {
        ""
    }

    func loadEpisodeArtworkUrl(podcastUuid: String, episodeUuid: String) async throws -> URL? {
        nil
    }

    func loadChapters(podcastUuid: String, episodeUuid: String) async throws -> ([PocketCastsDataModel.Episode.Metadata.EpisodeChapter]?, [podcasts.PodcastIndexChapter]?, [GeneratedChapter]?) {
        (nil, nil, generatedChapters)
    }

    func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
        return (transcripts: [], hasGeneratedTranscripts: true, isDisplayingGeneratedTranscript: true)
    }
}

private class ChapterReferenceTimeMappingMock: ChapterReferenceTimeMapping {
    let offset: TimeInterval
    var hasChapterReferenceMapping: Bool

    init(offset: TimeInterval, hasMapping: Bool) {
        self.offset = offset
        self.hasChapterReferenceMapping = hasMapping
    }

    func playbackTime(forReferenceTime referenceTime: TimeInterval) -> TimeInterval? {
        referenceTime + offset
    }
}
