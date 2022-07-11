import Foundation

struct CommonUpNextItem: Codable, Hashable {
    var episodeUuid: String
    var imageUrl: String
    var episodeTitle: String
    var podcastName: String
    var podcastColor: String
    var duration: TimeInterval
    var isPlaying: Bool = false
}
