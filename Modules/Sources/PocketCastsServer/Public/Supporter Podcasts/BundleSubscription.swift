import Foundation

public struct BundleSubscription: Codable {
    public var bundleUuid: String
    public var podcasts: [PodcastSubscription]
}
