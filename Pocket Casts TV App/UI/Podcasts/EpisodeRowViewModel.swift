import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

@Observable
class EpisodeRowViewModel: Identifiable {

    static func == (lhs: EpisodeRowViewModel, rhs: EpisodeRowViewModel) -> Bool {
        return lhs.episode.uuid == rhs.episode.uuid
    }

    var episode: BaseEpisode
    var podcast: Podcast?
    var imageData: Data?

    var id: String { episode.uuid }

    private let playbackManager: PlaybackManager

    init(episode: BaseEpisode, podcast: Podcast?, playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.episode = episode
        self.podcast = podcast
        self.playbackManager = playbackManager
    }

    func loadEpisodeArtwork() {
        Task.detached { [weak self] in
            let data = await self?.loadEpisodeArtworkData()
            await MainActor.run { [weak self] in
                self?.imageData = data
            }
        }
    }

    var duration: Double {
        return episode.duration
    }

    var playedUpTo: Double {
        return episode.playedUpTo
    }

    var displayTitle: String {
        return episode.displayableTitle()
    }

    var displaySubTitle: String {
        return episode.subTitle()
    }

    var displayInfo: String {
        return episode.displayableInfo()
    }

    var displayDate: String {
        return DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase
    }

    var displayDuration: String {
        return episode.displayableDuration
    }

    var timeLeft: String {
        return episode.displayableTimeLeft()
    }

    var displayImageData: Data? {
        return imageData
    }

    private func loadEpisodeArtworkData() async -> Data? {
        let imageUrl = ServerHelper.image(podcastUuid: episode.parentIdentifier(), size: 340)
        guard let url = URL(string: imageUrl),
              let (data, _) = try? await URLSession.shared.data(for: URLRequest(url: url)),
              let uiImage = UIImage(data: data)
        else {
            return nil
        }
        return uiImage.pngData()
    }

    var podcastUuid: String? {
        if let episode = episode as? Episode {
            return episode.podcastUuid
        } else {
            return nil
        }
    }

    func play() {
        if PlaybackManager.shared.isActivelyPlaying(episodeUuid: episode.uuid) {
            return
        } else {
            PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
        }
    }

    func playNext() {
        if playbackManager.inUpNext(episode: episode) {
            playbackManager.queue.move(episode: episode, to: 0)
        } else {
            playbackManager.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: true, userInitiated: true)
        }
        ToastManager.shared.show(L10n.playNextInUpNext)
    }

    func playLast() {
        if playbackManager.inUpNext(episode: episode) {
            let queueCount = playbackManager.queue.upNextCount()
            playbackManager.queue.move(episode: episode, to: max(queueCount - 1, 0))
        } else {
            playbackManager.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: false, userInitiated: true)
        }
        ToastManager.shared.show(L10n.playLastInUpNext)
    }

    func markAsPlayed() {
        EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.markPlayed)
    }

    var canArchive: Bool {
        episode is Episode
    }

    func archive() {
        guard let episode = episode as? Episode else { return }
        EpisodeManager.archiveEpisode(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.podcastArchived)
    }

    func removeFromUpNext() {
        playbackManager.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: true)
        ToastManager.shared.show(L10n.removeFromUpNext)
    }
}

@Observable
class MockEpisodeRowViewModel: Identifiable {

    let episode: Episode
    let podcast: Podcast?

    init(episode: Episode, podcast: Podcast?) {
        self.episode = episode
        self.podcast = podcast
    }

    static func == (lhs: MockEpisodeRowViewModel, rhs: MockEpisodeRowViewModel) -> Bool {
        return lhs.episode.uuid == rhs.episode.uuid
    }

    var id: String { episode.uuid }

    var displayTitle: String {
        return episode.displayableTitle()
    }

    var displayDate: String {
        return episode.shortPublishedDate()
    }

    var displayDuration: String {
        return episode.duration.formatted()
    }
}
