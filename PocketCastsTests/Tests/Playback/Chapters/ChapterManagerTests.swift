import XCTest

@testable import podcasts
@testable import PocketCastsDataModel

class ChapterManagerTests: XCTestCase {
    /// Update the current chapter given a TimeInterval
    func testUpdateCurrentChapterBasedOnTime() {
        let parserMock = PodcastChapterParserMock()
        parserMock.chapters = [
            chapterInfo(startTime: 0, duration: 100, shouldPlay: true),
            chapterInfo(startTime: 101, duration: 200, shouldPlay: false),
            chapterInfo(startTime: 201, duration: 300, shouldPlay: true),
            chapterInfo(startTime: 301, duration: 400, shouldPlay: false),
            chapterInfo(startTime: 401, duration: 500, shouldPlay: true),
            chapterInfo(startTime: 501, duration: 600, shouldPlay: false)
        ]
        let chapterManager = ChapterManager(chapterParser: parserMock)
        chapterManager.parseChapters(episode: EpisodeMock(), duration: 600)

        chapterManager.updateCurrentChapter(time: 10)

        XCTAssertEqual(chapterManager.currentChapters.visibleChapter, chapterInfo(startTime: 0, duration: 100, shouldPlay: true))
    }

    /// Update the current chapter given a TimeInterval
    func testReturnNextVisiblePlayableChapter() {
        let parserMock = PodcastChapterParserMock()
        parserMock.chapters = [
            chapterInfo(startTime: 0, duration: 100, shouldPlay: true),
            chapterInfo(startTime: 101, duration: 200, shouldPlay: false),
            chapterInfo(startTime: 201, duration: 300, shouldPlay: true),
            chapterInfo(startTime: 301, duration: 400, shouldPlay: false),
            chapterInfo(startTime: 401, duration: 500, shouldPlay: true),
            chapterInfo(startTime: 501, duration: 600, shouldPlay: false)
        ]
        let chapterManager = ChapterManager(chapterParser: parserMock)
        chapterManager.parseChapters(episode: EpisodeMock(), duration: 600)
        chapterManager.updateCurrentChapter(time: 10)

        let nextVisiblePlayableChapter = chapterManager.nextVisiblePlayableChapter()

        XCTAssertEqual(nextVisiblePlayableChapter, chapterInfo(startTime: 201, duration: 300, shouldPlay: true))
    }

    /// Update the current chapter given a TimeInterval
    func testReturnPreviousVisiblePlayableChapter() {
        let parserMock = PodcastChapterParserMock()
        parserMock.chapters = [
            chapterInfo(startTime: 0, duration: 100, shouldPlay: true),
            chapterInfo(startTime: 101, duration: 200, shouldPlay: false),
            chapterInfo(startTime: 201, duration: 300, shouldPlay: true),
            chapterInfo(startTime: 301, duration: 400, shouldPlay: false),
            chapterInfo(startTime: 401, duration: 500, shouldPlay: true),
            chapterInfo(startTime: 501, duration: 600, shouldPlay: false)
        ]
        let chapterManager = ChapterManager(chapterParser: parserMock)
        chapterManager.parseChapters(episode: EpisodeMock(), duration: 600)
        chapterManager.updateCurrentChapter(time: 450)

        let nextVisiblePlayableChapter = chapterManager.previousVisibleChapter()

        XCTAssertEqual(nextVisiblePlayableChapter, chapterInfo(startTime: 201, duration: 300, shouldPlay: true))
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
}

private class EpisodeMock: Episode {
    override var downloadUrl: String? {
        get { "https://pocketcasts.com/" }
        set {}
    }
}
