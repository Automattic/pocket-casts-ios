import Foundation

public struct UpNextItem {
    public var podcastUuid: String
    public var episodeUuid: String
    public var title: String?
    public var url: String
    public var published: Date
    public var hlsUrl: String?

    public init(podcastUuid: String, episodeUuid: String, title: String?, url: String, published: Date, hlsUrl: String? = nil) {
        self.podcastUuid = podcastUuid
        self.episodeUuid = episodeUuid
        self.title = title
        self.url = url
        self.published = published
        self.hlsUrl = hlsUrl
    }
}
