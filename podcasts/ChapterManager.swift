import Foundation
import PocketCastsDataModel

class ChapterManager {
    private var chapterParser = PodcastChapterParser()
    private var chapters = [ChapterInfo]()

    private var lastEpisodeUuid = ""

    var currentChapter: ChapterInfo?

    func chapterCount() -> Int {
        chapters.count
    }

    func haveTriedToParseChaptersFor(episodeUuid: String?) -> Bool {
        lastEpisodeUuid == episodeUuid
    }

    func previousChapter() -> ChapterInfo? {
        guard let currentChapter = currentChapter else {
            return nil
        }
        return chapters[safe: currentChapter.index - 1]
    }

    func nextChapter() -> ChapterInfo? {
        guard let currentChapter = currentChapter else { return nil }

        return chapters[safe: currentChapter.index + 1]
    }

    func chapterAt(index: Int) -> ChapterInfo? {
        chapters[safe: index]
    }

    @discardableResult
    func updateCurrentChapter(time: TimeInterval) -> Bool {
        if chapters.count == 0 { return false }

        let chapter = chapterForTime(time)
        let hasChanged = currentChapter != chapter

        if hasChanged { currentChapter = chapter }

        return hasChanged
    }

    func parseChapters(episode: BaseEpisode, duration: TimeInterval) {
        // store the last episode uuid we were asked to check chapters for, we use that below in case this method is called multiple times to not return old results
        lastEpisodeUuid = episode.uuid

        if episode.downloaded(pathFinder: DownloadManager.shared) {
            chapterParser.parseLocalFile(episode.pathToDownloadedFile(pathFinder: DownloadManager.shared), episodeDuration: duration) { [weak self] parsedChapters in
                if self?.lastEpisodeUuid == episode.uuid {
                    self?.handleChaptersLoaded(parsedChapters)
                }
            }
        } else if let url = EpisodeManager.urlForEpisode(episode) {
            chapterParser.parseRemoteFile(url.absoluteString, episodeDuration: duration) { [weak self] parsedChapters in
                if self?.lastEpisodeUuid == episode.uuid {
                    self?.handleChaptersLoaded(parsedChapters)
                }
            }
        }
    }

    func clearChapterInfo() {
        lastEpisodeUuid = ""
        chapters.removeAll()
        currentChapter = nil

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastChaptersDidUpdate)
    }

    func chapterForTime(_ time: TimeInterval) -> ChapterInfo? {
        chapters.filter { $0.startTime.seconds <= time }.last
    }

    private func handleChaptersLoaded(_ chapters: [ChapterInfo]) {
        self.chapters = chapters

        updateCurrentChapter(time: PlaybackManager.shared.currentTime())

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastChaptersDidUpdate)
    }
}
