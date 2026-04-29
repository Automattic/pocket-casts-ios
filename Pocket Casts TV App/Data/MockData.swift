import Foundation
import PocketCastsUtils

struct MockEpisode: Identifiable, Hashable, Equatable {
    var uuid: String
    var title: String
    var publishedDate: Date
    var duration: Double

    var id: String {
        return uuid
    }

    func displayableTitle() -> String {
        return title
    }
}

struct MockPodcast: Identifiable, Hashable, Equatable {
    var id: String
    var title: String
    var author: String?
    var podcastDescription: String?
    var image: String
    var episodes: [MockEpisode]
}

struct MockData {

    static func makePodcasts() -> [MockPodcast] {
        let numberOfPodcasts = 48
        var results = [MockPodcast]()
        for i in (0..<numberOfPodcasts) {
            var episodes: [MockEpisode] = []
            for i in (0..<numberOfPodcasts) {
                episodes.append(MockEpisode(uuid: UUID().uuidString, title: "Episode \(i+1)", publishedDate: Date.now.weeksAgo(i), duration: Double.random(in: (5.minutes...1.hours))))
            }
            results.append(MockPodcast(id: UUID().uuidString, title: "Podcast \(i+1)", author: "Author \(i+1)", podcastDescription: "Here is a fun description for this", image: "Covers/login-cover-\( (i % 10) + 1)", episodes: episodes))
        }
        return results
    }
}
