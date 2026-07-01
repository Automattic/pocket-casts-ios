import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import CoreMedia

/// Maps a time in the generated-content (reference) timeline onto the played
/// audio file's timeline. In the main app this is implemented by
/// `FingerprintTimingManager`; targets that don't include fingerprinting (App
/// Clip, watchOS, tvOS) simply leave the provider unset, so the adjustment is a
/// no-op there and generated chapters keep their reference times.
protocol ChapterReferenceTimeMapping: AnyObject {
    /// Whether a usable mapping is currently available.
    var hasChapterReferenceMapping: Bool { get }

    /// The played-file time for a time in the reference timeline, or `nil` if it
    /// can't be mapped.
    func playbackTime(forReferenceTime referenceTime: TimeInterval) -> TimeInterval?
}

/// Registered by the app once fingerprint timing is available. Stays `nil` in
/// targets without fingerprinting.
enum ChapterReferenceTimeMappingProvider {
    static var current: ChapterReferenceTimeMapping?
}

enum ChapterOrigin {
    case podcastIndex
    case nativeMedia
    case generated
    case showNotes
    case unknown

    var analyticsDescription: String {
        switch self {
        case .generated:
            "generated"
        case .nativeMedia:
            "native_media"
        case .showNotes:
            "show_notes"
        case .podcastIndex:
            "podcast_index"
        case .unknown:
            "unknown"
        }
    }
}

class ChapterManager {
    private var chapterParser = PodcastChapterParser()
    private var showInfoCoordinator: ShowInfoCoordinating
    private var chapters = [ChapterInfo]() {
        didSet {
            visibleChapters = chapters.filter { !$0.isHidden }
        }
    }
    private var visibleChapters = [ChapterInfo]()

    private var lastEpisodeUuid = ""

    /// Duration of the episode the current chapters belong to. Used to recompute
    /// generated-chapter durations after their start times are re-mapped.
    private var episodeDuration: TimeInterval = 0

    private var mappingObserver: NSObjectProtocol?

    var numberOfChaptersSkipped = 0

    var currentChapters = Chapters()

    var chaptersOrigin: ChapterOrigin = .unknown

    private var playableChapters: [ChapterInfo] {
        visibleChapters.filter { $0.isPlayable() }
    }

    init(
        chapterParser: PodcastChapterParser = PodcastChapterParser(),
        showInfoCoordinator: ShowInfoCoordinating = ShowInfoCoordinator.shared) {
        self.chapterParser = chapterParser
        self.showInfoCoordinator = showInfoCoordinator

        // The fingerprint mapping is built asynchronously and keeps growing during
        // playback, so re-align generated chapters whenever it advances.
        mappingObserver = NotificationCenter.default.addObserver(
            forName: Constants.Notifications.fingerprintTimingMappingUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyGeneratedChapterTiming()
        }
    }

    deinit {
        if let mappingObserver {
            NotificationCenter.default.removeObserver(mappingObserver)
        }
    }

    func visibleChapterCount() -> Int {
        visibleChapters.count
    }

    func playableChapterCount() -> Int {
        playableChapters.count
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

    func index(for chapter: Chapters) -> Int? {
        guard let visibleChapter = chapter.visibleChapter else {
            return nil
        }

        return playableChapters.firstIndex(of: visibleChapter)
    }

    @discardableResult
    func updateCurrentChapter(time: TimeInterval) -> Bool {
        if chapters.isEmpty { return false }

        let chapters = chaptersForTime(time)
        let hasChanged = currentChapters != chapters

        if hasChanged {
            currentChapters = chapters
        }

        return hasChanged
    }

    func parseChapters(episode: BaseEpisode, duration: TimeInterval) {
        Task.detached { [weak self] in
            await self?.parseChapters(episode: episode, duration: duration)
        }
    }

    func parseChapters(episode: BaseEpisode, duration: TimeInterval) async {
        // store the last episode uuid we were asked to check chapters for, we use that below in case this method is called multiple times to not return old results
        lastEpisodeUuid = episode.uuid
        episodeDuration = duration

        try? await parseLocalAndRemoteChapters(for: episode, duration: duration)
    }

    private func parseLocalAndRemoteChapters(for episode: BaseEpisode, duration: TimeInterval) async throws {
        // Parse chapters from the file and request external chapters
        async let fileChaptersAsync = loadChapters(for: episode, duration: duration)

        async let (podloveChaptersAsync, podcastIndexChaptersAsync, generatedChaptersAsync) = await
        showInfoCoordinator.loadChapters(podcastUuid: episode.parentIdentifier(), episodeUuid: episode.uuid)

        var chapters: [ChapterInfo]

        do {
            let (fileChapters, podloveChapters, podcastIndexChapters, generatedChapters) = try await (fileChaptersAsync, podloveChaptersAsync, podcastIndexChaptersAsync, generatedChaptersAsync)

            // Prioritize embedded chapters, given for some shows it will take
            // into account dynamic ads
            if !fileChapters.isEmpty {
                chapters = fileChapters
                FileLog.shared.addMessage("ChapterManager: using file chapters")
                chaptersOrigin = .nativeMedia
            } else if let externalChapters = parseExternalChapters(podlove: podloveChapters, podcastIndex: podcastIndexChapters, generated: generatedChapters, duration: duration) {
                chapters = externalChapters
                FileLog.shared.addMessage("ChapterManager: using external chapters")
            } else {
                chapters = []
                FileLog.shared.addMessage("ChapterManager: failed. Displaying no chapters.")
            }
        } catch {
            chapters = await fileChaptersAsync
            FileLog.shared.addMessage("ChapterManager: using file chapters because there was an error retrieving external sources")
        }

        if lastEpisodeUuid == episode.uuid {
            handleChaptersLoaded(chapters, for: episode)
        }
    }

    private func loadChapters(for episode: BaseEpisode, duration: TimeInterval) async -> [ChapterInfo] {
        if episode.downloaded(pathFinder: DownloadManager.shared) {
            return await chapterParser.parseLocalFile(episode.pathToDownloadedFile(pathFinder: DownloadManager.shared), episodeDuration: duration)
        } else if let url = EpisodeManager.urlForEpisode(episode) {
            return await chapterParser.parseRemoteFile(url.absoluteString, episodeDuration: duration)
        }

        return []
    }

    private func parseExternalChapters(podlove: [Episode.Metadata.EpisodeChapter]?, podcastIndex: [PodcastIndexChapter]?, generated: [GeneratedChapter]?, duration: TimeInterval) -> [ChapterInfo]? {
        if let podcastIndex {
            chaptersOrigin = .podcastIndex
            return chapterParser.parsePodcastIndexChapters(podcastIndex, episodeDuration: duration)
        }

        if let podlove {
            chaptersOrigin = .showNotes
            return chapterParser.parsePodloveChapters(podlove, episodeDuration: duration)
        }

        if let generated {
            chaptersOrigin = .generated
            return chapterParser.parseGeneratedChapters(generated, episodeDuration: duration)
        }

        chaptersOrigin = .unknown
        return nil
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

    var chaptersAnalyticsProperties: [String: Any] {
        return ["origin": chaptersOrigin.analyticsDescription]
    }

    private func handleChaptersLoaded(_ chapters: [ChapterInfo], for episode: BaseEpisode) {
        self.chapters = chapters

        episode.deselectedChapters?
            .split(separator: ",")
            .compactMap { Int($0) }
            .forEach { self.chapters[safe: $0]?.shouldPlay = false }

        // Apply any mapping that already exists; if none is ready yet the chapters
        // keep their reference times and get re-aligned once the mapping advances.
        // Skip the notification here since we post `podcastChaptersDidUpdate` below.
        applyGeneratedChapterTiming(notifyIfChanged: false)

        updateCurrentChapter(time: PlaybackManager.shared.currentTime())

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastChaptersDidUpdate)
    }

    /// Re-map generated chapter start times from the reference (transcript)
    /// timeline onto the played audio file's timeline using fingerprint timing,
    /// so chapter markers line up with what's actually playing when dynamic ads
    /// have shifted the real positions. No-op for other chapter sources, when no
    /// mapping is available, or in targets without fingerprinting.
    private func applyGeneratedChapterTiming(notifyIfChanged: Bool = true) {
        guard chaptersOrigin == .generated else { return }
        guard let mapper = ChapterReferenceTimeMappingProvider.current, mapper.hasChapterReferenceMapping else { return }

        // `chapters` is kept sorted by reference start time by the parser, and the
        // mapping is monotonic, so this order also holds in the played timeline.
        var didChange = false
        for chapter in chapters {
            guard let referenceTime = chapter.referenceStartTime?.seconds else { continue }
            let mappedTime = mapper.playbackTime(forReferenceTime: referenceTime) ?? referenceTime
            if abs(mappedTime - chapter.startTime.seconds) > 0.001 {
                chapter.startTime = CMTime(seconds: mappedTime, preferredTimescale: 1000000)
                didChange = true
            }
        }

        guard didChange else { return }

        // Durations are gaps between consecutive start times, so recompute them
        // from the adjusted values (the last chapter runs to the episode end).
        for (index, chapter) in chapters.enumerated() {
            if let nextChapter = chapters[safe: index + 1] {
                chapter.duration = max(0, nextChapter.startTime.seconds - chapter.startTime.seconds)
            } else {
                chapter.duration = max(0, episodeDuration - chapter.startTime.seconds)
            }
        }

        updateCurrentChapter(time: PlaybackManager.shared.currentTime())

        if notifyIfChanged {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastChaptersDidUpdate)
        }
    }
}
