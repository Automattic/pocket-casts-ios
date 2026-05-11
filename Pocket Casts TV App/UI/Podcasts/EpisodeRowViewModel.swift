import Foundation
import PocketCastsDataModel

@Observable
class EpisodeRowViewModel: Identifiable {

    static func == (lhs: EpisodeRowViewModel, rhs: EpisodeRowViewModel) -> Bool {
        return lhs.episode.uuid == rhs.episode.uuid
    }

    let episode: BaseEpisode
    let podcast: Podcast?

    var id: String { episode.uuid }

    init(episode: BaseEpisode, podcast: Podcast?) {
        self.episode = episode
        self.podcast = podcast
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
        return episode.shortPublishedDate()
    }

    var displayDuration: String {
        return episode.displayableDuration
    }

    var displayImageData: Data? {
        return nil
    }

    var podcastUuid: String? {
        if let episode = episode as? Episode {
            return episode.podcastUuid
        } else {
            return nil
        }
    }
}

@Observable
class MockEpisodeRowViewModel: Identifiable {

    let episode: MockEpisode
    let podcast: MockPodcast?

    init(episode: MockEpisode, podcast: MockPodcast?) {
        self.episode = episode
        self.podcast = podcast
    }

    static func == (lhs: MockEpisodeRowViewModel, rhs: MockEpisodeRowViewModel) -> Bool {
        return lhs.episode.uuid == rhs.episode.uuid
    }

    var id: String { episode.uuid }

    var displayTitle: String {
        return episode.title
    }

    var displayDate: String {
        return episode.publishedDate.formatted()
    }

    var displayDuration: String {
        return episode.duration.formatted()
    }

}
