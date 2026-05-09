import Foundation
import PocketCastsDataModel

struct EpisodeRowViewModel: Identifiable, Hashable {
    let uuid: String
    let title: String
    let publishedDate: Date
    let duration: Double
    let podcastUUID: String?
    let imageName: String?

    var podcastTitle: String?
    var podcastDescription: String?

    var id: String { uuid }

    init(episode: BaseEpisode, podcastUUID: String? = nil, podcastTitle: String? = nil, podcastDescription: String? = nil) {
        self.uuid = episode.uuid
        self.title = episode.title ?? ""
        self.publishedDate = episode.publishedDate ?? Date()
        self.duration = episode.duration
        self.podcastUUID = podcastUUID ?? (episode as? Episode)?.podcastUuid
        self.imageName = nil
        self.podcastTitle = podcastTitle
        self.podcastDescription = podcastDescription
    }

    init(mockEpisode: MockEpisode, podcastTitle: String? = nil, podcastDescription: String? = nil) {
        self.uuid = mockEpisode.uuid
        self.title = mockEpisode.title
        self.publishedDate = mockEpisode.publishedDate
        self.duration = mockEpisode.duration
        self.podcastUUID = nil
        self.imageName = mockEpisode.image
        self.podcastTitle = podcastTitle
        self.podcastDescription = podcastDescription
    }
}
