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
    var network: String?
    var website: String?
    var frequency: String?
    var nextEpisodeDate: String?
}

struct MockPlaylist: Identifiable, Hashable, Equatable {
    var id: String
    var title: String
    var manual: Bool
    var episodes: [MockEpisode]
    var color: Color
}

struct MockData {

    private static let podcastNames = [
        "The Daily", "Serial", "Radiolab", "This American Life",
        "99% Invisible", "Freakonomics Radio", "How I Built This",
        "Planet Money", "The Moth", "Conan O'Brien Needs a Friend",
        "SmartLess", "Armchair Expert", "WTF with Marc Maron",
        "Reply All", "Heavyweight", "Criminal", "Revisionist History",
        "Hidden Brain", "Stuff You Should Know", "TED Radio Hour",
        "The Joe Rogan Experience", "Call Her Daddy", "My Favorite Murder",
        "Sword and Scale", "Lore", "S-Town", "Snap Judgment",
        "Invisibilia", "Up First", "Fresh Air", "Pod Save America",
        "The Ben Shapiro Show", "Darknet Diaries", "Song Exploder",
        "Everything Everywhere Daily", "Philosophize This!",
        "The Happiness Lab", "Lex Fridman Podcast", "Hardcore History",
        "No Such Thing As A Fish", "Science Vs", "Throughline",
        "Slow Burn", "Ear Hustle", "Wind of Change", "Dolly Parton's America",
        "Nice White Parents", "The Ezra Klein Show"
    ]

    private static let authorNames = [
        "The New York Times", "Sarah Koenig", "WNYC Studios", "Ira Glass",
        "Roman Mars", "Dubner Productions", "Guy Raz / NPR",
        "NPR", "The Moth", "Team Coco", "Wondery", "Dax Shepard",
        "Marc Maron", "Gimlet Media", "Jonathan Goldstein", "Phoebe Judge",
        "Malcolm Gladwell", "Shankar Vedantam", "iHeartPodcasts", "TED",
        "Spotify", "Barstool Sports", "Exactly Right", "Incongruity",
        "Aaron Mahnke", "Serial Productions", "Snap Judgment",
        "NPR", "NPR", "NPR", "Crooked Media", "The Daily Wire",
        "Jack Rhysider", "Hrishikesh Hirway", "Gary Arndt",
        "Stephen West", "Dr. Laurie Santos", "Lex Fridman", "Dan Carlin",
        "QI", "Gimlet Media", "NPR", "Slate", "PRX",
        "Pineapple Street Studios", "WNYC Studios", "Serial Productions",
        "New York Times Opinion"
    ]

    private static let episodeTitles = [
        "The Search for Life Beyond Earth",
        "Why We Can't Stop Scrolling",
        "Inside the Algorithm",
        "The Last Day of Pompeii",
        "How Music Hijacks Your Brain",
        "The $70 Billion Ghost",
        "What Happens When You Die?",
        "The Spy Who Changed Everything",
        "Why Do We Dream?",
        "The Secret History of Coffee",
        "Lost Cities of the Amazon",
        "The Psychology of Conspiracy Theories",
        "How Language Shapes Thought",
        "The Rise and Fall of Theranos",
        "What AI Can't Do (Yet)",
        "The Ocean's Deepest Secrets",
        "Why Nostalgia Is Good for You",
        "The Man Who Solved the Market",
        "How Pandemics End",
        "The Science of Addiction",
        "Living on Mars: A Reality Check",
        "The Forgotten Women of NASA",
        "Why We Procrastinate",
        "The Dark Side of Social Media",
        "How Trees Talk to Each Other",
        "The Mystery of Dark Matter",
        "Why Sleep Is Your Superpower",
        "The Economics of Happiness",
        "How Your Gut Controls Your Brain",
        "The Art of Negotiation",
        "When Algorithms Go Wrong",
        "The History of the Internet",
        "Why Silence Is So Loud",
        "The Future of Work",
        "How Cults Recruit Normal People",
        "The Science Behind Déjà Vu",
        "What Makes a Song a Hit?",
        "The Hidden Cost of Fast Fashion",
        "Why We Love True Crime",
        "The Next Pandemic",
        "How Memory Works (and Fails)",
        "The Ethics of Gene Editing",
        "Why Cities Make Us Lonely",
        "The Power of Boredom",
        "How Volcanoes Changed History",
        "The Truth About Multitasking",
        "Why We Need Strangers",
        "The Invention of Money"
    ]

    private static var podcasts: [MockPodcast] = []

    static func makePodcasts() -> [MockPodcast] {
        guard podcasts.isEmpty else {
            return podcasts
        }
        let numberOfPodcasts = 48
        var results = [MockPodcast]()
        for i in (0..<numberOfPodcasts) {
            var episodes: [MockEpisode] = []
            let podcastImageName = "Covers/login-cover-\( (i % 10) + 1)"
            for j in (0..<numberOfPodcasts) {
                let titleIndex = (i + j) % episodeTitles.count
                episodes.append(MockEpisode(uuid: UUID().uuidString, title: episodeTitles[titleIndex], publishedDate: Date.now.weeksAgo(j), duration: Double.random(in: (5.minutes...1.hours)), image: podcastImageName))
            }
            let frequencies = ["Released weekly", "Released daily", "Released biweekly", "Released monthly"]
            let nextDays = ["Next episode Monday", "Next episode Tuesday", "Next episode Wednesday", "Next episode Thursday", "Next episode Friday"]
            results.append(MockPodcast(
                id: UUID().uuidString,
                title: podcastNames[i % podcastNames.count],
                author: authorNames[i % authorNames.count],
                podcastDescription: "Here is a fun description for this",
                image: podcastImageName,
                episodes: episodes,
                network: authorNames[i % authorNames.count],
                website: "https://\(podcastNames[i % podcastNames.count].lowercased().replacingOccurrences(of: " ", with: "")).com",
                frequency: frequencies[i % frequencies.count],
                nextEpisodeDate: nextDays[i % nextDays.count]
            ))
        }
        self.podcasts = results
        return self.podcasts
    }

    static private var playlists: [MockPlaylist] = []

    static func makePlaylists() -> [MockPlaylist] {
        guard playlists.isEmpty else {
            return playlists
        }
        let numberOfEpisodes = 12
        var results = [MockPlaylist]()
        let playlistsSpec: [(String, Bool, Color)] = [
            ("New releases", true, Color(red: 0.15, green: 0.25, blue: 0.5)),
            ("In progress", true, Color(red: 0.5, green: 0.17, blue: 0.15)),
            ("TV Stuff", false, Color(red: 0.21, green: 0.22, blue: 0.14)),
            ("My favorites", true, Color(red: 0.5, green: 0.35, blue: 0.12))
        ]
        let podcasts = makePodcasts()
        for (index, (name, smart, color)) in playlistsSpec.enumerated() {
            var episodes: [MockEpisode] = []
            for i in (0..<Int.random(in: 0..<numberOfEpisodes)) {
                let podcast = podcasts.randomElement()
                if let episode = podcast?.episodes.randomElement() {
                    episodes.append(episode)
                }
            }
            results.append(MockPlaylist(id: UUID().uuidString, title: name, manual: !smart, episodes: episodes, color: color))
        }
        self.playlists = results
        return results
    }

    static var upNext: [MockEpisode] = []

    static func makeUpNext() -> [MockEpisode] {
        guard upNext.isEmpty else {
            return upNext
        }
        let numberOfEpisodes = 48
        var episodes: [MockEpisode] = []
        for i in (0..<numberOfEpisodes) {
            let podcast = podcasts.randomElement()
            if let episode = podcast?.episodes.randomElement() {
                episodes.append(episode)
            }
        }
        upNext = episodes
        return episodes
    }
}
