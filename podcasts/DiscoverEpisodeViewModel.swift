import Combine
import Foundation
import Kingfisher
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class DiscoverEpisodeViewModel: ObservableObject {
    private enum ClientError: Swift.Error {
        case noPodcastUuid
        case podcastNotFound
        case episodeNotFound
    }

    weak var delegate: DiscoverDelegate?

    // Episode Details
    @Published var episodeUUID: String? = nil
    @Published var title: String = ""
    @Published var podcastTitle: String = ""
    @Published var seasonInfo: String? = nil
    @Published var imageUUID: String? = nil
    @Published var episodeDuration: String? = nil
    @Published var publishedDate: String? = nil
    @Published var isTrailer: Bool = false
    
    @Published var listTitle: String = ""

    @Published var discoverEpisode: DiscoverEpisode? = nil
    @Published var discoverCollection: PodcastCollection? = nil
    @Published var discoverItem: DiscoverItem? = nil
    var listId: String?

    private var cancellables = Set<AnyCancellable>()
    private let playbackManager: ServerPlaybackDelegate

    init(playbackManager: ServerPlaybackDelegate = PlaybackManager.shared) {
        self.playbackManager = playbackManager
        $discoverItem
            .dropFirst()
            .flatMap { DiscoverServerHandler.shared.discoverItem($0?.source, type: PodcastCollection?.self) }
            .replaceError(with: nil)
            .assign(to: &$discoverCollection)

        $discoverCollection
            .dropFirst()
            .map { $0?.episodes?.first }
            .replaceError(with: nil)
            .receive(on: RunLoop.main)
            .assign(to: &$discoverEpisode)

        $discoverEpisode
            .receive(on: ImmediateScheduler.shared)
            .sink(receiveValue: { [weak self] episode in
                guard let self = self else { return }
                self.episodeUUID = episode?.uuid
                self.title = episode?.title ?? ""
                self.imageUUID = episode?.podcastUuid
                self.podcastTitle = episode?.podcastTitle ?? ""
                self.isTrailer = episode?.isTrailer ?? false

                if let episodeDuration = episode?.duration, episodeDuration > 0 {
                    self.episodeDuration = TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episodeDuration))
                }
                else {
                    self.episodeDuration = nil
                }

                if let published = episode?.published {
                    self.publishedDate = DateFormatHelper.sharedHelper.tinyLocalizedFormatter.string(from: published)
                }
                else {
                    self.publishedDate = nil
                }

                let seasonNumber = episode?.season ?? 0
                let episodeNumber = episode?.number ?? 0

                if seasonNumber == 0, episodeNumber == 0 {
                    self.seasonInfo = nil
                }
                else {
                    self.seasonInfo = L10n.seasonEpisodeShorthand(seasonNumber: Int64(seasonNumber),
                                                                  episodeNumber: Int64(episodeNumber),
                                                                  shortFormat: true)
                }
            })
            .store(in: &cancellables)
    }

    public func registerListImpression() {
        guard let listId = discoverItem?.uuid else { return }
        AnalyticsHelper.listImpression(listId: listId)
    }

    public func didSelectPlayEpisode() {
        guard let episodeUuid = discoverEpisode?.uuid,
              let podcastUuid = discoverEpisode?.podcastUuid else { return }

        let listId = discoverItem?.uuid ?? listId

        DiscoverEpisodeViewModel.loadPodcast(podcastUuid, ensureEpisodeUuid: episodeUuid)
            .sink { [unowned self] _ in
                // We don't need the fetched podcast but we want to make sure the episode is available.

                if self.playbackManager.isActivelyPlaying(episodeUuid: episodeUuid) {
                    PlaybackActionHelper.pause()
                }
                else if let baseEpisode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) {
                    if let listId = listId {
                        AnalyticsHelper.podcastEpisodePlayedFromList(listId: listId, podcastUuid: podcastUuid)
                    }
                    PlaybackActionHelper.play(episode: baseEpisode, podcastUuid: podcastUuid)
                }
            }
            .store(in: &cancellables)
    }

    public func didSelectEpisode() {
        guard let episode = discoverEpisode,
              let podcastUuid = episode.podcastUuid,
              let episodeUuid = episode.uuid else { return }

        if let listId = discoverItem?.uuid ?? listId {
            AnalyticsHelper.podcastEpisodeTapped(fromList: listId, podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        }

        DiscoverEpisodeViewModel.loadPodcast(podcastUuid, ensureEpisodeUuid: episode.uuid)
            .receive(on: RunLoop.main)
            .sink { [weak self] podcast in
                guard let podcast = podcast else { return }
                self?.delegate?.show(discoverEpisode: episode, podcast: podcast)
            }
            .store(in: &cancellables)
    }

    // MARK: Static helpers

    static func loadPodcast(_ podcastUUID: String, ensureEpisodeUuid: String? = nil) -> AnyPublisher<Podcast?, Never> {
        Future<Podcast?, ClientError> { promise in
            if let existingPodcast = DataManager.sharedManager.findPodcast(uuid: podcastUUID, includeUnsubscribed: true) {

                if let episodeUuid = ensureEpisodeUuid {
                    DiscoverEpisodeViewModel.ensureEpisodeExists(podcast: existingPodcast, episodeUuid: episodeUuid) { exists in
                        if exists {
                            promise(.success(existingPodcast))
                        }
                        else {
                            promise(.failure(.episodeNotFound))
                        }
                    }
                    return
                }

                promise(.success(existingPodcast))
                return
            }

            ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUUID, subscribe: false) { added in
                if added, let existingPodcast = DataManager.sharedManager.findPodcast(uuid: podcastUUID, includeUnsubscribed: true) {
                    if let episodeUuid = ensureEpisodeUuid {
                        DiscoverEpisodeViewModel.ensureEpisodeExists(podcast: existingPodcast, episodeUuid: episodeUuid) { exists in
                            if exists {
                                promise(.success(existingPodcast))
                            }
                            else {
                                promise(.failure(.episodeNotFound))
                            }
                        }
                        return
                    }

                    promise(.success(existingPodcast))
                }
                else {
                    promise(.failure(.podcastNotFound))
                }
            }
        }
        .replaceError(with: nil)
        .eraseToAnyPublisher()
    }

    /**
        Checks if a specific episode of a podcast exists, if not refreshes the episode list and notifies if the episode was successfully found or not.
     */
    static func ensureEpisodeExists(podcast: Podcast, episodeUuid: String, completion: ((Bool) -> Void)?) {
        let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid)

        if episode == nil {
            ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast) { _ in
                let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid)

                if episode == nil {
                    completion?(false)
                }
                else {
                    completion?(true)
                }
            }
            return

        }
        completion?(true)
        return
    }
}
