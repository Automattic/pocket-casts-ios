import Combine
import Foundation
import PocketCastsDataModel

class EpisodeViewModel: ObservableObject {
    @Published var episode: BaseEpisode
    @Published var inUpNext = false
    @Published var downloadProgress: DownloadProgress?

    let playSourceViewModel = PlaySourceHelper.playSourceViewModel
    var cancellables = Set<AnyCancellable>()
    var alreadyHydrated = false

    init(episode: BaseEpisode, skipHydration: Bool = false) {
        self.episode = episode
        if !skipHydration {
            hydrate()
        }
    }

    func hydrate() {
        if alreadyHydrated {
            return
        }
        alreadyHydrated = true
        if episode.hasOnlyUuid {
            episode = DataManager.sharedManager.findBaseEpisode(uuid: episode.uuid) ?? episode
        }
        inUpNext = playSourceViewModel.inUpNext(forEpisode: episode)

        if episode.downloading() {
            downloadProgress = DownloadManager.shared.progressManager.progressForEpisode(self.episode.uuid)
        }

        Publishers.Notification.downloadStatusChanged
            .compactMap { [unowned self] notification in
                guard let episodeUuid = notification.object as? String, episodeUuid == self.episode.uuid else { return nil }
                self.downloadProgress = nil
                return DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$episode)

        Publishers.Notification.downloadProgress
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] notification in
                guard let episodeUuid = notification.object as? String, episodeUuid == self.episode.uuid else { return }

                if !self.episode.downloading(), let fetchedEpisode = DataManager.sharedManager.findBaseEpisode(uuid: self.episode.uuid) {
                    self.episode = fetchedEpisode
                }

                self.downloadProgress = DownloadManager.shared.progressManager.progressForEpisode(self.episode.uuid)
            })
            .store(in: &cancellables)

        Publishers.Notification.upNextEpisodeChanged
            .compactMap { [unowned self] notification in
                guard let episodeUuid = notification.object as? String, episodeUuid == self.episode.uuid else { return nil }
                return self.episode
            }
            .map { [unowned self] episode in
                self.playSourceViewModel.inUpNext(forEpisode: episode)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$inUpNext)

        Publishers.Notification.upNextQueueChanged
            .map { [unowned self] _ in
                self.playSourceViewModel.inUpNext(forEpisode: self.episode)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$inUpNext)
    }
}
