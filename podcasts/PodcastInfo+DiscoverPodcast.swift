import PocketCastsServer

extension PodcastInfo {
    init(_ podcast: DiscoverPodcast) {
        self.init()
        self.uuid   = podcast.uuid
        self.title  = podcast.title
        self.author = podcast.author
    }
}
