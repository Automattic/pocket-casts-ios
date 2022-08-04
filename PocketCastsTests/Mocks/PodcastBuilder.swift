import Foundation

@testable import PocketCastsDataModel

/// Creates a Podcast with a random `id` and `uuid`
class PodcastBuilder {
    let podcast: Podcast

    init() {
        podcast = Podcast()
        podcast.id = Int64(UInt64.random(in: 0 ... 100))
        podcast.uuid = NSUUID().uuidString
    }

    func build() -> Podcast {
        podcast
    }
}
