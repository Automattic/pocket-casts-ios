import XCTest

@testable import podcasts

final class ChaptersTests: XCTestCase {

    private let maxInvisibleChapterDuration: TimeInterval = 15

    private func visibleChapter(title: String = "visible chapter",
                                url: String = "https://visiblechapter",
                                image: UIImage? = nil,
                                index: Int = 0,
                                duration: TimeInterval = 30,
                                startTime: CMTime = CMTime(seconds: 30, preferredTimescale: 1000)) -> ChapterInfo {
        let chapter = ChapterInfo()
        chapter.title = title
        chapter.isHidden = false
        chapter.duration = duration
        chapter.startTime = startTime
        chapter.index = index
        chapter.url = url
        chapter.image = image
        return chapter
    }

    private lazy var singleChapter: Chapters = {
        Chapters(chapters: [ChapterInfo()])!
    }()

    private lazy var fiveChapters: Chapters = {
        Chapters(chapters: [ChapterInfo](repeating: ChapterInfo(), count: 5))!
    }()

    private lazy var visibleChapterOnly: Chapters = {
        Chapters(chapters: [visibleChapter()])!
    }()

    private func invisibleChaptersOnly(baseStartTime: CMTime = CMTime(seconds: 10, preferredTimescale: 1000)) -> Chapters {
        var chapters = [ChapterInfo]()
        for i in 0 ..< 3 {
            let chapter = ChapterInfo()
            chapter.isHidden = true
            chapter.title = "invisible chapter \(i)"
            chapter.duration = maxInvisibleChapterDuration - TimeInterval(i)
            chapter.startTime = baseStartTime + CMTime(seconds: Double(i), preferredTimescale: 1000)
            chapter.index = -1
            chapter.url = "https://invisiblechapter\(i)"
            chapter.image = UIImage()
            chapters.append(chapter)
        }
        return Chapters(chapters: chapters)!
    }

    private func detailsOnVisibleChapterOnly(title: String = "visible chapter",
                                             url: String = "https://visible.url.data",
                                             image: UIImage? = nil,
                                             index: Int = 1,
                                             duration: TimeInterval = 30,
                                             startTime: CMTime = CMTime(seconds: 30, preferredTimescale: 1000)) -> Chapters {
        var chapters = [ChapterInfo]()
        for i in 0 ..< 4 {
            let chapter = ChapterInfo()
            chapter.isHidden = true
            chapter.duration = maxInvisibleChapterDuration
            chapter.startTime = startTime + CMTime(seconds: Double(i), preferredTimescale: 1000)
            chapter.index = -1
            chapters.append(chapter)
        }
        chapters.insert(visibleChapter(title: title, url: url, image: image, index: index, duration: duration, startTime: startTime), at: 0)
        return Chapters(chapters: chapters)!
    }

    private func detailsOnFirstChapter(title: String = "invisible chapter",
                                        url: String = "https://url.data",
                                        image: UIImage? = nil) -> Chapters {
        var chapters = [ChapterInfo]()
        for i in 0 ..< 4 {
            let chapter = ChapterInfo()
            chapter.isHidden = true
            chapter.duration = maxInvisibleChapterDuration
            chapter.startTime = CMTime(seconds: Double(i), preferredTimescale: 1000)
            chapter.index = -1
            chapters.append(chapter)
        }
        chapters.insert(visibleChapter(title: "visible chapter", startTime: CMTime(seconds: 0, preferredTimescale: 1000)), at: 0)
        chapters[1].title = title
        chapters[1].url = url
        chapters[1].image = image
        return Chapters(chapters: chapters)!
    }

    private func detailsOnMiddleChapter(title: String = "invisible chapter",
                                        url: String = "https://url.data",
                                        image: UIImage? = nil) -> Chapters {
        var chapters = [ChapterInfo]()
        for i in 0 ..< 4 {
            let chapter = ChapterInfo()
            chapter.isHidden = true
            chapter.duration = maxInvisibleChapterDuration
            chapter.startTime = CMTime(seconds: Double(i), preferredTimescale: 1000)
            chapter.index = -1
            if i < 2 {
                chapter.title = "invisible chapter \(i)"
                chapter.url = "https://url.data\(i)"
                chapter.image = UIImage()
            }
            chapters.append(chapter)
        }
        chapters[1].title = title
        chapters[1].url = url
        chapters[1].image = image
        chapters.insert(visibleChapter(title: "visible chapter", startTime: CMTime(seconds: 0, preferredTimescale: 1000)), at: 0)
        return Chapters(chapters: chapters)!
    }

    private func detailsOnLastChapter(title: String = "invisible chapter",
                                    url: String = "https://url.data",
                                    image: UIImage? = nil) -> Chapters {
        var chapters = [ChapterInfo]()
        for i in 0 ..< 4 {
            let chapter = ChapterInfo()
            chapter.isHidden = true
            chapter.duration = maxInvisibleChapterDuration
            chapter.startTime = CMTime(seconds: Double(i), preferredTimescale: 1000)
            chapter.index = -1
            chapter.title = "invisible chapter \(i)"
            chapter.url = "https://url.data\(i)"
            chapter.image = UIImage()
            chapters.append(chapter)
        }
        chapters.insert(visibleChapter(title: "visible chapter", startTime: CMTime(seconds: 0, preferredTimescale: 1000)), at: 0)
        chapters.last?.title = title
        chapters.last?.url = url
        chapters.last?.image = image
        return Chapters(chapters: chapters)!
    }

    func testNilObjectWhenChaptersDontOverlap() {
        let chapter1 = ChapterInfo()
        chapter1.duration = 15
        chapter1.startTime = CMTime(seconds: 0, preferredTimescale: 1000)
        let chapter2 = ChapterInfo()
        chapter2.duration = 15
        chapter2.startTime = CMTime(seconds: 15, preferredTimescale: 1000)

        let chapters = Chapters(chapters: [chapter1, chapter2])

        XCTAssertNil(chapters)
    }

    func testNonNilObjectWhenChapterRangesAreEqual() {
        let chapter1 = ChapterInfo()
        chapter1.duration = 15
        chapter1.startTime = CMTime(seconds: 15, preferredTimescale: 1000)
        let chapter2 = ChapterInfo()
        chapter2.duration = 15
        chapter2.startTime = CMTime(seconds: 15, preferredTimescale: 1000)

        let chapters = Chapters(chapters: [chapter1, chapter2])

        XCTAssertNotNil(chapters)
    }

    func testNonNilObjectWhenChaptersOverlap() {
        let chapter1 = ChapterInfo()
        chapter1.duration = 15
        chapter1.startTime = CMTime(seconds: 7, preferredTimescale: 1000)
        let chapter2 = ChapterInfo()
        chapter2.duration = 15
        chapter2.startTime = CMTime(seconds: 15, preferredTimescale: 1000)

        let chapters = Chapters(chapters: [chapter1, chapter2])

        XCTAssertNotNil(chapters)
    }

    func testChapterCountIsOne() {
        let chapters = singleChapter
        XCTAssertEqual(chapters.count, 1)
    }

    func testChapterCountIsFive() {
        let chapters = fiveChapters
        XCTAssertEqual(chapters.count, 5)
    }

    func testVisibleChapterIsFound() {
        let chapters = visibleChapterOnly
        XCTAssertNotNil(chapters.visibleChapter)
    }

    func testVisibleChapterNotFound() {
        let chapters = invisibleChaptersOnly()
        XCTAssertNil(chapters.visibleChapter)
    }

    func testIndexIsThatOfVisibleChapter() {
        let index = 3
        let chapters = detailsOnVisibleChapterOnly(index: index)
        XCTAssertEqual(index, chapters.index)
    }

    func testIndexForInvisibleChaptersOnly() {
        let chapters = invisibleChaptersOnly()
        XCTAssertEqual(-1, chapters.index)
    }

    func testTitleTakesValueOfVisibleChapterWhereHiddenChaptersDontHaveTitles() {
        let title = "visible chapter"
        let chapters = detailsOnVisibleChapterOnly(title: title)
        XCTAssertEqual(title, chapters.title)
    }

    func testTitleTakeValueOfFirstHiddenChapter() {
        let title = "test title"
        let chapters = detailsOnFirstChapter(title: title)
        XCTAssertEqual(title, chapters.title)
    }

    func testTitleTakeValueOfMiddleHiddenChapter() {
        let title = "test title"
        let chapters = detailsOnMiddleChapter(title: title)
        XCTAssertEqual(title, chapters.title)
    }

    func testTitleTakeValueOfLastHiddenChapter() {
        let title = "test title"
        let chapters = detailsOnLastChapter(title: title)
        XCTAssertEqual(title, chapters.title)
    }

    func testUrlTakesValueOfVisibleChapterWhereHiddenChaptersDontHaveUrls() {
        let url = "https://visible.url"
        let chapters = detailsOnVisibleChapterOnly(url: url)
        XCTAssertEqual(url, chapters.url)
    }

    func testUrlTakeValueOfFirstHiddenChapter() {
        let url = "https://first.url"
        let chapters = detailsOnFirstChapter(url: url)
        XCTAssertEqual(url, chapters.url)
    }

    func testUrlTakeValueOfMiddleHiddenChapter() {
        let url = "https://middle.url"
        let chapters = detailsOnMiddleChapter(url: url)
        XCTAssertEqual(url, chapters.url)
    }

    func testUrlTakeValueOfLastHiddenChapter() {
        let url = "https://last.url"
        let chapters = detailsOnLastChapter(url: url)
        XCTAssertEqual(url, chapters.url)
    }

    func testImageTakesValueOfVisibleChapter() {
        let image = UIImage(systemName: "iphone")
        let chapters = detailsOnVisibleChapterOnly(image: image)
        XCTAssertEqual(image, chapters.artwork)
    }

    func testImageTakesValueOfFirstHiddenChapter() {
        let image = UIImage(systemName: "iphone")
        let chapters = detailsOnFirstChapter(image: image)
        XCTAssertEqual(image, chapters.artwork)
    }

    func testImageTakesValueOfMiddleHiddenChapter() {
        let image = UIImage(systemName: "iphone")
        let chapters = detailsOnMiddleChapter(image: image)
        XCTAssertEqual(image, chapters.artwork)
    }

    func testImageTakesValueOfLastHiddenChapter() {
        let image = UIImage(systemName: "iphone")
        let chapters = detailsOnLastChapter(image: image)
        XCTAssertEqual(image, chapters.artwork)
    }

    func testDurationIsFromVisibleChapter() {
        let duration: TimeInterval = 30
        let chapters = detailsOnVisibleChapterOnly(duration: duration)
        XCTAssertEqual(duration, chapters.duration)
    }

    func testDurationIsFromVisibleChapterWithShortestDuration() {
        let duration = maxInvisibleChapterDuration / 2
        let chapters = detailsOnVisibleChapterOnly(duration: duration)
        XCTAssertEqual(duration, chapters.duration)
    }

    func testDurationIsLongestDuration() {
        let chapters = invisibleChaptersOnly()
        XCTAssertEqual(maxInvisibleChapterDuration, chapters.duration)
    }

    func testStartTimeIsFromVisibleChapter() {
        let startTime = CMTime(seconds: 15, preferredTimescale: 1000)
        let chapters = detailsOnVisibleChapterOnly(startTime: startTime)
        XCTAssertEqual(startTime, chapters.startTime)
    }

    func testStartTimeIsEarliestStartTimeOfInvisibleChapters() {
        let baseStartTime = CMTime(seconds: 15, preferredTimescale: 1000)
        let chapters = invisibleChaptersOnly(baseStartTime: baseStartTime)
        XCTAssertEqual(baseStartTime, chapters.startTime)
    }
}
