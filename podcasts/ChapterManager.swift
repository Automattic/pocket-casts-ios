import Foundation
import PocketCastsDataModel

class ChapterManager {
    private var chapterParser = PodcastChapterParser()
    private var chapters = [ChapterInfo]() {
        didSet {
            visibleChapters = chapters.filter { !$0.isHidden }
        }
    }
    private var visibleChapters = [ChapterInfo]()

    private var lastEpisodeUuid = ""

    var numberOfChaptersSkipped = 0

    var currentChapters = Chapters()

    init(chapterParser: PodcastChapterParser = PodcastChapterParser()) {
        self.chapterParser = chapterParser
    }

    func visibleChapterCount() -> Int {
        visibleChapters.count
    }

    func playableChapterCount() -> Int {
        visibleChapters.filter { $0.isPlayable() }.count
    }

    func haveTriedToParseChaptersFor(episodeUuid: String?) -> Bool {
        lastEpisodeUuid == episodeUuid
    }

    func previousVisibleChapter() -> ChapterInfo? {
        guard let visibleChapter = currentChapters.visibleChapter else {
            return nil
        }
        let previousChapter: ChapterInfo?

        if let index = visibleChapters.firstIndex(of: visibleChapter) {
            previousChapter = visibleChapters.enumerated().filter { $0.offset < index && $0.element.isPlayable() }.map { $0.element }.last
        } else {
            previousChapter = nil
        }
        return previousChapter
    }

    func nextVisiblePlayableChapter() -> ChapterInfo? {
        guard let visibleChapter = currentChapters.visibleChapter else {
            return nil
        }
        let nextChapter: ChapterInfo?

        if let index = visibleChapters.firstIndex(of: visibleChapter) {
            nextChapter = visibleChapters.enumerated().first { $0.offset > index && $0.element.isPlayable() }.map { $0.element }
        } else {
            nextChapter = nil
        }
        return nextChapter
    }

    var lastChapter: ChapterInfo? {
        visibleChapters.last
    }

    func chapterAt(index: Int) -> ChapterInfo? {
        visibleChapters[safe: index]
    }

    func playableChapterAt(index: Int) -> ChapterInfo? {
        visibleChapters.filter({ $0.isPlayable() })[safe: index]
    }

    @discardableResult
    func updateCurrentChapter(time: TimeInterval) -> Bool {
        if chapters.count == 0 { return false }

        let chapters = chaptersForTime(time)
        let hasChanged = currentChapters != chapters

        if hasChanged {
            currentChapters = chapters
        }

        return hasChanged
    }

    func parseChapters(episode: BaseEpisode, duration: TimeInterval) {
        // store the last episode uuid we were asked to check chapters for, we use that below in case this method is called multiple times to not return old results
        lastEpisodeUuid = episode.uuid

        if episode.downloaded(pathFinder: DownloadManager.shared) {
            chapterParser.parseLocalFile(episode.pathToDownloadedFile(pathFinder: DownloadManager.shared), episodeDuration: duration) { [weak self] parsedChapters in
                if self?.lastEpisodeUuid == episode.uuid {
                    self?.handleChaptersLoaded(parsedChapters, for: episode)
                }
            }
        } else if let url = EpisodeManager.urlForEpisode(episode) {
            chapterParser.parseRemoteFile(url.absoluteString, episodeDuration: duration) { [weak self] parsedChapters in
                if self?.lastEpisodeUuid == episode.uuid {
                    self?.handleChaptersLoaded(parsedChapters, for: episode)
                }
            }
        }
    }

    func clearChapterInfo() {
        lastEpisodeUuid = ""
        chapters.removeAll()
        currentChapters = Chapters()

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastChaptersDidUpdate)
    }

    func chaptersForTime(_ time: TimeInterval) -> Chapters {
        Chapters(chapters: chapters.filter { $0.startTime.seconds <= time && ($0.startTime.seconds + $0.duration) > time })
    }

    private func handleChaptersLoaded(_ chapters: [ChapterInfo], for episode: BaseEpisode) {
        self.chapters = chapters

        episode.deselectedChapters?
            .split(separator: ",")
            .compactMap { Int($0) }
            .forEach { self.chapters[safe: $0]?.shouldPlay = false }

        updateCurrentChapter(time: PlaybackManager.shared.currentTime())

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastChaptersDidUpdate)
    }
}
