import UIKit

class Chapters: Equatable {
    private var chapters = [ChapterInfo]()

    var visibleChapter: ChapterInfo? {
        chapters.last(where: { !$0.isHidden })
    }

    var title: String {
        chapters.last(where: { !$0.title.isEmpty })?.title ?? ""
    }

    var count: Int {
        chapters.count
    }

    var index: Int {
        visibleChapter?.index ?? -1
    }

    var url: String? {
        chapters.last(where: { $0.url != nil })?.url
    }

    var startTime: CMTime {
        visibleChapter?.startTime ??
        chapters.min(by: { $0.startTime < $1.startTime} )?.startTime ??
        CMTime()
    }

    var duration: TimeInterval {
        visibleChapter?.duration ??
        chapters.max(by: { $0.duration < $1.duration })?.duration ??
        1
    }

#if !os(watchOS)
    var artwork: UIImage? {
        chapters.last(where: { $0.image != nil })?.image
    }
#endif

    init() {
        self.chapters = []
    }

    init?(chapters: [ChapterInfo]) {
        if !chaptersOverlap(chapters) {
            return nil
        }
        self.chapters = chapters
    }

    static func == (lhs: Chapters, rhs: Chapters) -> Bool {
        lhs.chapters.elementsEqual(rhs.chapters)
    }
}

private func chaptersOverlap(_ chapters: [ChapterInfo]) -> Bool {
    let ranges = chapters.compactMap { $0.duration > 0 ? $0.startTime.seconds ... ($0.startTime.seconds + $0.duration) : nil }
    var ranegsOverlap = true
    var lowerbound = -Double.infinity, upperbound = Double.infinity

    for r in ranges {
        var didSet = false
        if r.lowerBound >= lowerbound && r.lowerBound < upperbound {
            lowerbound = r.lowerBound
            didSet = true
        }

        if r.upperBound <= upperbound && r.upperBound > lowerbound {
            upperbound = r.upperBound
            didSet = true
        }

        if !didSet {
            ranegsOverlap = false
            break
        }
    }
    return ranegsOverlap
}
