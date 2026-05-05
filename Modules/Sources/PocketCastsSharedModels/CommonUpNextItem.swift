import Foundation

public struct CommonUpNextItem: Codable, Hashable {
    public var episodeUuid: String
    public var imageUrl: String
    public var episodeTitle: String
    public var podcastName: String
    public var podcastColor: String
    public var duration: TimeInterval
    public var isPlaying: Bool

    public init(
        episodeUuid: String,
        imageUrl: String,
        episodeTitle: String,
        podcastName: String,
        podcastColor: String,
        duration: TimeInterval,
        isPlaying: Bool = false
    ) {
        self.episodeUuid = episodeUuid
        self.imageUrl = imageUrl
        self.episodeTitle = episodeTitle
        self.podcastName = podcastName
        self.podcastColor = podcastColor
        self.duration = duration
        self.isPlaying = isPlaying
    }
}
