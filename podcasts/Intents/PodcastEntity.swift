import AppIntents
import PocketCastsDataModel
import PocketCastsServer

struct PodcastEntity: AppEntity {
    static let defaultQuery = PodcastEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(stringLiteral: "Podcast")

    let id: String

    @Property(title: "Title of podcast")
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            stringLiteral: title
        )
    }

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

extension PodcastEntity {
    init(_ podcast: Podcast) {
        id = podcast.uuid
        title = podcast.title ?? ""
    }

    init(searchResult: PodcastFolderSearchResult) {
        id = searchResult.uuid
        title = searchResult.title ?? ""
    }
}

struct PodcastEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [PodcastEntity.ID]) async throws -> [PodcastEntity] {
        let podcasts = identifiers.compactMap { DataManager.sharedManager.findPodcast(uuid: $0) }
        return podcasts.map { PodcastEntity($0) }
    }

    func suggestedEntities() async throws -> [PodcastEntity] {
        let podcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        return podcasts.map { PodcastEntity($0) }
    }

    func entities(matching string: String) async throws -> [PodcastEntity] {
        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        let filteredPodcasts = allPodcasts.filter { podcast in
            guard let title = podcast.title else { return false }
            return title.localizedCaseInsensitiveContains(string) ||
                   podcast.author?.localizedCaseInsensitiveContains(string) == true
        }
        return filteredPodcasts.map { PodcastEntity($0) }
    }
}
