import Foundation
import PocketCastsUtils
import SwiftUI

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

    var image: String
}

struct MockPodcast: Identifiable, Hashable, Equatable {
    var id: String
    var title: String
    var author: String?
    var podcastDescription: String?
    var image: String
    var episodes: [MockEpisode]
}

struct MockPlaylist: Identifiable, Hashable, Equatable {
    var id: String
    var title: String
    var manual: Bool
    var episodes: [MockEpisode]
    var color: Color
}

struct MockData {

    static func makePodcasts() -> [MockPodcast] {
        let numberOfPodcasts = 48
        var results = [MockPodcast]()
        for i in (0..<numberOfPodcasts) {
            var episodes: [MockEpisode] = []
            let podcastImageName = "Covers/login-cover-\( (i % 10) + 1)"
            for i in (0..<numberOfPodcasts) {
                episodes.append(MockEpisode(uuid: UUID().uuidString, title: "Episode \(i+1)", publishedDate: Date.now.weeksAgo(i), duration: Double.random(in: (5.minutes...1.hours)), image: podcastImageName))
            }
            results.append(MockPodcast(id: UUID().uuidString, title: "Podcast \(i+1)", author: "Author \(i+1)", podcastDescription: "Here is a fun description for this", image: podcastImageName, episodes: episodes))
        }
        return results
    }

    static func makePlaylists() -> [MockPlaylist] {
        let numberOfEpisodes = 12
        var results = [MockPlaylist]()
        let playlistsSpec: [(String, Bool, Color)] = [
            ("New releases", true, Color(red: 0.15, green: 0.25, blue: 0.5)),
            ("In progress", true, Color(red: 0.5, green: 0.17, blue: 0.15)),
            ("TV Stuff", false, Color(red: 0.21, green: 0.22, blue: 0.14)),
            ("My favorites", true, Color(red: 0.5, green: 0.35, blue: 0.12))
        ]
        for (name, smart, color) in playlistsSpec {
            var episodes: [MockEpisode] = []
            for i in (0..<numberOfEpisodes) {
                let podcastImageName = "Covers/login-cover-\( Int.random(in: (1..<10)))"
                episodes.append(MockEpisode(uuid: UUID().uuidString, title: "Episode \(i+1)", publishedDate: Date.now.weeksAgo(i), duration: Double.random(in: (5.minutes...1.hours)), image: podcastImageName))
            }
            results.append(MockPlaylist(id: UUID().uuidString, title: name, manual: !smart, episodes: episodes, color: color))
        }
        return results
    }
}
