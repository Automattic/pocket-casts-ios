import AppIntents
import PocketCastsDataModel
import PocketCastsServer

// Async wrappers for ServerPodcastManager methods
extension ServerPodcastManager {
    func addFromUuid(podcastUuid: String) async -> Podcast? {
        return await withCheckedContinuation { continuation in
            addFromUuid(podcastUuid: podcastUuid, subscribe: false, autoDownloads: 0) { success in
                if success {
                    let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true)
                    continuation.resume(returning: podcast)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func updatePodcastIfRequired(podcast: Podcast) async -> Bool {
        return await withCheckedContinuation { continuation in
            updatePodcastIfRequired(podcast: podcast, addMissingEpisodes: false) { success in
                continuation.resume(returning: success)
            }
        }
    }

    func addPodcastFromUpNextItem(podcastUuid: String, episodeUuid: String, episodeTitle: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let upNextItem = UpNextItem(
                podcastUuid: podcastUuid,
                episodeUuid: episodeUuid,
                title: episodeTitle,
                url: "",
                published: Date()
            )

            ServerPodcastManager.shared.addPodcastFromUpNextItem(upNextItem) { success in
                continuation.resume(returning: success)
            }
        }
    }
}

struct EpisodeSearchEntity: AppEntity {
    static let defaultQuery = EpisodeSearchEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(stringLiteral: "Episode")

    let id: String

    @Property(title: "Title of episode")
    var title: String

    @Property(title: "Podcast title")
    var podcastTitle: String

    @Property(title: "Podcast UUID")
    var podcastUuid: String

    @Property(title: "Episode UUID")
    var episodeUuid: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "from \(podcastTitle)"
        )
    }

    init(id: String, title: String, podcastTitle: String) {
        self.id = id
        self.title = title
        self.podcastTitle = podcastTitle
        self.podcastUuid = String(id.split(separator: "/").first!)
        self.episodeUuid = String(id.split(separator: "/").last!)
    }

    init(episodeUuid: String, title: String, podcastTitle: String, podcastUuid: String) {
        self.id = "\(podcastUuid)/\(episodeUuid)"
        self.title = title
        self.podcastTitle = podcastTitle
        self.podcastUuid = podcastUuid
        self.episodeUuid = episodeUuid
    }
}

extension EpisodeSearchEntity {
    init(searchResult: EpisodeSearchResult) {
        id = "\(searchResult.podcastUuid)/\(searchResult.uuid)"
        title = searchResult.title
        podcastTitle = searchResult.podcastTitle
        episodeUuid = searchResult.uuid
        podcastUuid = searchResult.podcastUuid
    }
}

struct EpisodeSearchEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [EpisodeSearchEntity.ID]) async throws -> [EpisodeSearchEntity] {
        var entities: [EpisodeSearchEntity] = []

        for identifier in identifiers {
            // Parse the composite ID (podcastUuid/episodeUuid)
            let components = identifier.split(separator: "/", maxSplits: 1)
            guard components.count == 2 else {
                // Invalid ID format, skip
                continue
            }

            let podcastUuid = String(components[0])
            let episodeUuid = String(components[1])

            // First try to find the episode in the local database
            if let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid),
               let podcast = episode.parentPodcast() {
                entities.append(EpisodeSearchEntity(
                    episodeUuid: episode.uuid,
                    title: episode.title ?? "",
                    podcastTitle: podcast.title ?? "",
                    podcastUuid: podcast.uuid
                ))
            } else {
                // Episode not found locally, use addPodcastFromUpNextItem to handle podcast/episode fetching
                let success = await ServerPodcastManager.shared.addPodcastFromUpNextItem(
                    podcastUuid: podcastUuid,
                    episodeUuid: episodeUuid,
                    episodeTitle: "Episode" // placeholder title, will be updated from server
                )

                if success {
                    // Try to find the episode again after adding podcast and episode
                    if let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid),
                       let podcast = episode.parentPodcast() {
                        entities.append(EpisodeSearchEntity(
                            episodeUuid: episode.uuid,
                            title: episode.title ?? "",
                            podcastTitle: podcast.title ?? "",
                            podcastUuid: podcast.uuid
                        ))
                    } else {
                        // Still not found, create entity with what we know
                        entities.append(EpisodeSearchEntity(
                            episodeUuid: episodeUuid,
                            title: "Episode", // placeholder
                            podcastTitle: "Podcast", // placeholder
                            podcastUuid: podcastUuid
                        ))
                    }
                }
            }
        }

        return entities
    }

    func suggestedEntities() async throws -> [EpisodeSearchEntity] {
        // Return recent episodes from all podcasts
        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        var recentEpisodes: [EpisodeSearchEntity] = []

        for podcast in allPodcasts.prefix(10) { // Limit to avoid too many results
            let latestEpisodes = DataManager.sharedManager.findLatestEpisodes(podcast: podcast, limit: 3)
            let entities = latestEpisodes.map { episode in
                EpisodeSearchEntity(
                    episodeUuid: episode.uuid,
                    title: episode.title ?? "",
                    podcastTitle: podcast.title ?? "",
                    podcastUuid: podcast.uuid
                )
            }
            recentEpisodes.append(contentsOf: entities)
        }

        return recentEpisodes
    }

    func entities(matching string: String) async throws -> [EpisodeSearchEntity] {
        let customWhere = "title LIKE '%\(string)%' OR description LIKE '%\(string)%'"
        let episodes = DataManager.sharedManager.findEpisodesWhere(customWhere: customWhere, arguments: nil)
        return episodes.compactMap { episode in
            guard let podcast = episode.parentPodcast() else { return nil }
            return EpisodeSearchEntity(
                episodeUuid: episode.uuid,
                title: episode.title ?? "",
                podcastTitle: podcast.title ?? "",
                podcastUuid: podcast.uuid
            )
        }
    }
}
