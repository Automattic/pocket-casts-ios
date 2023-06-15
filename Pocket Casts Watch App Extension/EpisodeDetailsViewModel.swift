import Combine
import Foundation
import PocketCastsDataModel

class EpisodeDetailsViewModel: EpisodeViewModel {
    @Published var shouldDismiss = false
    @Published var isPlaying = false
    @Published var isCurrentlyPlaying = false
    @Published var actionRequiresConfirmation: EpisodeAction?
    @Published var actions: [EpisodeAction] = []
    @Published var supportsPodcastNavigation = false

    var parentPodcast: Podcast? {
        (episode as? Episode)?.parentPodcast()
    }

    private var playbackChanged: AnyPublisher<BaseEpisode, Never> {
        Publishers.Merge(
            $episode,
            Publishers.Notification.playbackChanged.map { [unowned self] _ in self.episode }.eraseToAnyPublisher()
        )
        .eraseToAnyPublisher()
    }

    private var updateEpisode: AnyPublisher<Notification, Never> {
        Publishers.Merge3(
            Publishers.Notification.episodeArchiveStatusChanged,
            Publishers.Notification.episodeStarredChanged,
            Publishers.Notification.dataUpdated
        )
        .eraseToAnyPublisher()
    }

    override init(episode: BaseEpisode) {
        super.init(episode: episode)

        playbackChanged
            .map { [unowned self] episode in
                self.playSourceViewModel.isPlaying(forEpisode: episode)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$isPlaying)

        playbackChanged
            .map { [unowned self] episode in
                self.playSourceViewModel.isCurrentlyPlaying(episode: episode)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$isCurrentlyPlaying)

        Publishers.CombineLatest3(playbackChanged, $isCurrentlyPlaying, $inUpNext)
            .map { [unowned self] episode, isCurrentlyPlayingEpisode, inUpNext in
                var actions = [EpisodeAction]()

                // Download actions
                if self.playSourceViewModel.downloaded(episode: episode) {
                    actions.append(.deleteDownload)
                } else if episode.downloading() || episode.queued() {
                    actions.append(.pauseDownload)
                } else {
                    actions.append(.download)
                }

                // Up Next actions
                if inUpNext {
                    actions.append(.removeFromQueue)
                }

                if !isCurrentlyPlayingEpisode {
                    actions.append(contentsOf: [.playNext, .playLast])
                }

                if let episode = episode as? Episode {
                    // Archive actions
                    actions.append(episode.archived ? .unarchive : .archive)

                    // Star actions
                    actions.append(episode.keepEpisode ? .unstar : .star)
                }

                // Mark played actions
                actions.append(episode.played() ? .markUnplayed : .markPlayed)

                return actions
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: &$actions)

        $episode
            .map { [unowned self] episode in
                self.playSourceViewModel.supportsPodcastNavigation(forEpisode: episode)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$supportsPodcastNavigation)

        updateEpisode
            .compactMap { [unowned self] _ in
                let currentEpisode = self.episode
                return self.playSourceViewModel.fetchEpisode(uuid: currentEpisode.uuid)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$episode)

        Publishers.Notification.userEpisodeDeleted
            .map { [unowned self] notification -> BaseEpisode? in
                let currentEpisode = self.episode
                guard let uuid = notification.object as? String, currentEpisode.uuid == uuid else { return currentEpisode }
                return self.playSourceViewModel.fetchEpisode(uuid: currentEpisode.uuid)
            }
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] fetchedEpisode in
                if let fetchedEpisode = fetchedEpisode {
                    self.episode = fetchedEpisode
                } else {
                    self.shouldDismiss = true
                }
            })
            .store(in: &cancellables)
    }

    func playPauseTapped() {
        playSourceViewModel.playPauseTapped(withEpisode: episode)
    }

    func handleEpisodeAction(_ action: EpisodeAction, wasConfirmed: Bool = false, dismiss: () -> Void) {
        let recievedConfirmation = !playSourceViewModel.requiresConfirmation(forAction: action) || wasConfirmed
        guard recievedConfirmation else {
            actionRequiresConfirmation = action
            return
        }

        switch action {
        case .download:
            playSourceViewModel.download(episode: episode)
        case .pauseDownload:
            playSourceViewModel.pauseDownload(forEpisode: episode)
        case .deleteDownload:
            playSourceViewModel.deleteDownload(forEpisode: episode)
        case .removeFromQueue:
            playSourceViewModel.removeFromUpNext(episode: episode)
        case .playNext:
            playSourceViewModel.addToUpNext(episode: episode, toTop: true)
        case .playLast:
            playSourceViewModel.addToUpNext(episode: episode, toTop: false)
        case .archive:
            playSourceViewModel.archive(episode: episode)
        case .unarchive:
            playSourceViewModel.unarchive(episode: episode)
        case .star:
            playSourceViewModel.setStarred(true, episode: episode)
        case .unstar:
            playSourceViewModel.setStarred(false, episode: episode)
        case .markPlayed:
            playSourceViewModel.markPlayed(episode: episode)
        case .markUnplayed:
            playSourceViewModel.markAsUnplayed(episode: episode)
        }

        if action.shouldDismiss {
            dismiss()
        }
    }
}
