import PocketCastsDataModel
import PocketCastsServer
import SwiftUI

class EndOfYear2024StoriesModel: StoryModel {
    static let year = 2024
    var stories = [EndOfYear2024Story]()
    var data = EndOfYear2024StoriesData()

    var indicatorColor: Color {
        .black
    }

    var primaryBackgroundColor: Color {
        Color(hex: "EE661C")
    }

    required init() { }

    func populate(with dataManager: DataManager) {
        var stories = [EndOfYear2024Story]()
        // First, search for top 5 podcasts
        let topPodcasts = dataManager.topPodcasts(in: Self.year, limit: 10)

        if !topPodcasts.isEmpty {
            data.top8Podcasts = Array(topPodcasts.suffix(8)).map { $0.podcast }.reversed()
            data.topPodcasts = Array(topPodcasts.prefix(5))
            stories.append(.top5Podcasts)
            stories.append(.topSpot)
        }

        // Listening time
        if let listeningTime = dataManager.listeningTime(in: Self.year),
           listeningTime > 0, !topPodcasts.isEmpty {
            stories.append(.listeningTime)
            data.listeningTime = listeningTime
        }

        // Ratings
        if let ratings = dataManager.summarizedRatings(in: Self.year) {
            data.ratings = ratings
        }
        stories.append(.ratings) // Gets added regardless of the count since we have a fallback empty screen

        // Longest episode
        if let longestEpisode = dataManager.longestEpisode(in: Self.year),
           let podcast = longestEpisode.parentPodcast() {
            data.longestEpisode = longestEpisode
            data.longestEpisodePodcast = podcast
            stories.append(.longestEpisode)

            // Listened podcasts and episodes
            let listenedNumbers = dataManager.listenedNumbers(in: Self.year)
            if listenedNumbers.numberOfEpisodes > 0
                && listenedNumbers.numberOfPodcasts > 0
                && !topPodcasts.isEmpty {
                data.listenedNumbers = listenedNumbers
                stories.append(.numberOfPodcastsAndEpisodesListened)
            }
        }

        // Year over year listening time
        let yearOverYearListeningTime = dataManager.yearOverYearListeningTime(in: Self.year)
        if yearOverYearListeningTime.totalPlayedTimeThisYear != 0 ||
            yearOverYearListeningTime.totalPlayedTimeLastYear != 0 {
            data.yearOverYearListeningTime = yearOverYearListeningTime
            stories.append(.yearOverYearListeningTime)
        }

        // Completion Rate
        data.episodesStartedAndCompleted = dataManager.episodesStartedAndCompleted(in: Self.year)
        stories.append(.completionRate)

        self.stories = stories
    }

    func story(for storyNumber: Int) -> any StoryView {
        switch stories[storyNumber] {
        case .intro:
            return IntroStory2024()
        case .numberOfPodcastsAndEpisodesListened:
            return NumberListened2024(listenedNumbers: data.listenedNumbers, podcasts: data.top8Podcasts)
        case .topSpot:
            return TopSpotStory2024(topPodcast: data.topPodcasts.first!)
        case .top5Podcasts:
            return Top5Podcasts2024Story(top5Podcasts: data.topPodcasts)
        case .ratings:
            return Ratings2024Story(ratings: data.ratings)
        case .listeningTime:
            return ListeningTime2024Story(listeningTime: data.listeningTime)
        case .longestEpisode:
            return LongestEpisode2024Story(episode: data.longestEpisode, podcast: data.longestEpisodePodcast)
        case .yearOverYearListeningTime:
            return YearOverYearCompare2024Story(subscriptionTier: SubscriptionHelper.activeTier, listeningTime: data.yearOverYearListeningTime)
        case .completionRate:
            return CompletionRate2024Story(subscriptionTier: SubscriptionHelper.activeTier, startedAndCompleted: data.episodesStartedAndCompleted)
        case .epilogue:
            return EpilogueStory2024()
        }
    }

    func isInteractiveView(for storyNumber: Int) -> Bool {
        switch stories[storyNumber] {
        case .epilogue:
            return true
        case .top5Podcasts:
            return true
        case .ratings:
            return true
        default:
            return false
        }
    }

    func shouldLoadData(in dataManager: DataManager) -> Bool {
        // Load data if our `ratings` property is empty
        // Other data is handled in `EndOfYearStoriesBuilder`
        dataManager.ratings.ratings == nil
    }

    func isReady() -> Bool {
        if stories.isEmpty {
            return false
        }

        stories.append(.intro)
        stories.append(.epilogue)

        stories.sortByCaseIterableIndex()

        return true
    }

    var numberOfStories: Int {
        stories.count
    }

    func paywallView() -> AnyView {
        AnyView(PaidStoryWallView2024(subscriptionTier: SubscriptionHelper.activeTier))
    }

    func overlaidShareView() -> AnyView? {
        nil
    }

    func footerShareView() -> AnyView? {
        AnyView(shareView())
    }

    func sharingSnapshotModifier(_ view: AnyView) -> AnyView {
        AnyView(view
        .safeAreaInset(edge: .bottom) {
            Image("logo_pill")
                .resizable()
                .frame(width: 153, height: 36)
                .padding(.top, 16)
                .padding(.bottom, 26)
        })
    }

    @ViewBuilder func shareView() -> some View {
        Button(L10n.eoyShare) {
            StoriesController.shared.share()
        }
        .buttonStyle(BasicButtonStyle(textColor: .black, backgroundColor: Color.clear, borderColor: .black))
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
    }
}


/// An entity that holds data to present EoY 2024 stories
class EndOfYear2024StoriesData {
    var topPodcasts: [TopPodcast] = []

    var listeningTime: Double = 0

    var longestEpisode: Episode!

    var longestEpisodePodcast: Podcast!

    var listenedNumbers: ListenedNumbers!

    var top8Podcasts: [Podcast] = []

    var episodesStartedAndCompleted: EpisodesStartedAndCompleted!

    var yearOverYearListeningTime: YearOverYearListeningTime!

    var ratings: [UInt32: Int] = [:]
}
