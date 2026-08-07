import Foundation
import PocketCastsUtils
import PocketCastsDataModel
import PocketCastsServer
import SwiftUI

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

    static var stubPodcasts: [Podcast] = []

    static func makeStubPodcasts() -> [Podcast] {
        guard stubPodcasts.isEmpty else {
            return stubPodcasts
        }
        let frequencies = ["Released weekly", "Released daily", "Released biweekly", "Released monthly"]
        let numberOfPodcasts = 48
        var results = [Podcast]()
        for i in (0..<numberOfPodcasts) {
            let podcast = Podcast()
            podcast.id = Int64(i)
            podcast.uuid = UUID().uuidString
            podcast.title = podcastNames[i % podcastNames.count]
            podcast.author = authorNames[i % authorNames.count]
            podcast.podcastDescription = "Here is a fun description for this"
            podcast.podcastUrl = "https://\(podcastNames[i % podcastNames.count].lowercased().replacingOccurrences(of: " ", with: "")).com"
            podcast.episodeFrequency = frequencies[i % frequencies.count]
            podcast.estimatedNextEpisode = Date.now.advanced(by: 1.days)
            results.append(podcast)
        }
        self.stubPodcasts = results
        return self.stubPodcasts
    }

    /// Real Pocket Casts podcast UUIDs, so mock podcasts render real artwork from
    /// the image CDN instead of blank placeholders in previews and demos.
    static let artworkUUIDs = [
        "e7a6f7d0-02f2-0133-1c51-059c869cc4eb",
        "da3271a0-69e7-0132-d9fd-5f4c86fd3263",
        "3782b780-0bc5-012e-fb02-00163e1b201c",
        "9349e8d0-a87f-013a-d8af-0acc26574db2",
        "82e37e80-755d-0138-eddc-0acc26574db2",
        "9478cc80-7c42-0138-edfe-0acc26574db2",
        "37082d70-e945-0137-b6eb-0acc26574db2",
        "62200ab0-b7ec-0139-f606-0acc26574db2",
        "b0689300-ecd3-012e-e054-525400c11844",
        "68504d20-dc2b-012e-da14-525400c11844",
        "43e949f0-60ec-0131-7415-723c91aeae46"
    ]

    static var stubArtworkPodcasts: [Podcast] = []

    /// Stub podcasts whose `uuid` resolves to real artwork on the image CDN.
    /// Use these where the mock should look populated (e.g. the signing-in animation).
    static func makeStubArtworkPodcasts() -> [Podcast] {
        guard stubArtworkPodcasts.isEmpty else {
            return stubArtworkPodcasts
        }
        var results = [Podcast]()
        for (i, uuid) in artworkUUIDs.enumerated() {
            let podcast = Podcast()
            podcast.id = Int64(i)
            podcast.uuid = uuid
            podcast.title = podcastNames[i % podcastNames.count]
            podcast.author = authorNames[i % authorNames.count]
            results.append(podcast)
        }
        stubArtworkPodcasts = results
        return results
    }

    private static func makeStubFolder(name: String, podcastCount: Int, from allPodcasts: [Podcast], startIndex: Int) -> Folder {
        let folderPodcasts = Array(allPodcasts[startIndex..<min(startIndex + podcastCount, allPodcasts.count)])
        let folder = Folder()
        folder.uuid = UUID().uuidString
        folder.name =  name
        folder.color = 0
        for podcast in folderPodcasts {
            podcast.folderUuid = folder.uuid
        }
        return folder
    }

    static var stubFolders: [Folder] = []

    static func makeStubFolders() -> [Folder] {
        guard stubFolders.isEmpty else { return stubFolders }
        let allPodcasts = makeStubPodcasts()
        let result = [
            makeStubFolder(name: "News", podcastCount: 4, from: allPodcasts, startIndex: 0),
            makeStubFolder(name: "Comedy", podcastCount: 1, from: allPodcasts, startIndex: 4),
            makeStubFolder(name: "Tech", podcastCount: 2, from: allPodcasts, startIndex: 5),
            makeStubFolder(name: "Science", podcastCount: 3, from: allPodcasts, startIndex: 7),
            makeStubFolder(name: "My super duper long folder name that keeps on going", podcastCount: 4, from: allPodcasts, startIndex: 10)
        ]
        self.stubFolders = result
        return result
    }

    static let sampleMediaURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!

    static var stubEpisodes: [Episode] = []
    static func makeStubEpisodes() -> [Episode] {
        guard stubEpisodes.isEmpty else { return stubEpisodes }
        let allPodcasts = makeStubPodcasts()
        var episodes: [Episode] = []
        for j in (0..<allPodcasts.count) {
            let podcast = allPodcasts[j]
            for i in (0..<8) {
                let titleIndex = (i + j) % episodeTitles.count
                let episode = Episode()
                episode.uuid = UUID().uuidString
                episode.title = episodeTitles[titleIndex]
                episode.publishedDate = Date.now.weeksAgo(j)
                episode.duration = Double.random(in: (5.minutes...1.hours))
                episode.playedUpTo = Double.random(in: (0...episode.duration))
                episode.podcastUuid = podcast.uuid
                episode.downloadUrl = sampleMediaURL.absoluteString
                episodes.append(episode)
            }
        }
        stubEpisodes = episodes
        return stubEpisodes
    }

    private static var stubPlaylists: [EpisodeFilter] = []

    static let playlistsSpec: [(String, Bool, Color)] = [
        ("New releases", true, Color(red: 0.15, green: 0.25, blue: 0.5)),
        ("In progress", true, Color(red: 0.5, green: 0.17, blue: 0.15)),
        ("TV Stuff", false, Color(red: 0.21, green: 0.22, blue: 0.14)),
        ("My favorites", true, Color(red: 0.5, green: 0.35, blue: 0.12))
    ]

    static func makeStubPlaylists() -> [EpisodeFilter] {
        guard stubPlaylists.isEmpty else {
            return stubPlaylists
        }
        let numberOfEpisodes = 12
        var results = [EpisodeFilter]()

        for (i, (name, smart, _)) in playlistsSpec.enumerated() {
            var episodes: [Episode] = Self.makeStubEpisodes()
            for _ in (0..<Int.random(in: 0..<numberOfEpisodes)) {
                if let episode = episodes.randomElement() {
                    episodes.append(episode)
                }
            }
            let playlist = EpisodeFilter()
            playlist.uuid = UUID().uuidString
            playlist.playlistName = name
            playlist.manual = !smart
            playlist.customIcon = 0
            playlist.sortPosition = Int32(i)
            results.append(playlist)
        }
        self.stubPlaylists = results
        return results
    }

    static func makeStubDiscoveryPodcast() -> DiscoverPodcast {
        var podcast = DiscoverPodcast()
        podcast.uuid = UUID().uuidString
        podcast.title = podcastNames.first
        podcast.author = authorNames.first
        podcast.shortDescription = episodeTitles.first

        return podcast
    }

    static func makeStubDiscoveryPodcasts() -> [DiscoverPodcast] {
        var result = [DiscoverPodcast]()
        for (index, name) in podcastNames.enumerated() {
            var podcast = DiscoverPodcast()
            podcast.uuid = UUID().uuidString
            podcast.title = name
            podcast.author = authorNames[index]
            podcast.shortDescription = episodeTitles[index]

            result.append(podcast)
        }

        return result
    }

    static func makeStubVideoEpisodePodcasts() -> [DiscoverEpisode] {
        var result = [DiscoverEpisode]()
        let podcastsUuids: [String] = ["b0689300-ecd3-012e-e054-525400c11844", "68504d20-dc2b-012e-da14-525400c11844", "43e949f0-60ec-0131-7415-723c91aeae46"]
        let podcastsNames: [String] = ["This Week in Tech (Video)", "TED Talks Music", "Daily Tech News Show (VIDEO)"]
        let episodesUuid: [String] = ["ed625ff3-d996-4d82-8921-0b823297bdfc", "cede2a30-0163-0133-1b93-059c869cc4eb", "5806902f-7214-46db-a7f7-78d2b0141a5f"]
        let episodesTitle: [String] = ["The Great Beagle Migration - Pope Leo XIV's 1st Encyclical & Ferrari's 1st EV", "An 11-year-old prodigy performs old-school jazz | Joey Alexander", "The Practical Ferrari – DTNS Live 5129"]
        let urls: [String] = ["https://pscrb.fm/rss/p/mgln.ai/e/294/cdn.twit.tv/video/twit/twit1086/twit1086_h264m_1920x1080.mp4", "https://download.ted.com/products/87704.mp4?apikey=172BB350-0009", "https://dtns.muffincdn.com/DTNS20260528.mp4"]

        for (index, uuid) in podcastsUuids.enumerated() {
            let episode = DiscoverEpisode(uuid: episodesUuid[index], title: episodesTitle[index], duration: 600, url: urls[index], podcastUuid: uuid, podcastTitle: podcastsNames[index], type: nil, published: Date.now, season: 0, number: 0)

            result.append(episode)
        }

        return result
    }

    static func makeStubBanner(_ type: BannerType) -> DiscoverItem {
        return DiscoverItem(id: type.rawValue, type: "banner", summaryStyle: "inline_banner", regions: [])
    }
}
