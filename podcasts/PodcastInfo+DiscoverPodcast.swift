import PocketCastsServer

extension PodcastInfo {
    init(_ podcast: DiscoverPodcast) {
        var info = Self()
        info.uuid = podcast.uuid
        info.title = podcast.title
        info.author = podcast.author
        self = info
    }
}
