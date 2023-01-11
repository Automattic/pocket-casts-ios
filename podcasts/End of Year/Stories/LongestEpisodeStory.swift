import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct LongestEpisodeStory: ShareableStory {
    let duration: TimeInterval = 5.seconds

    var identifier: String = "longest_episode"

    let episode: Episode

    let podcast: Podcast

    var backgroundColor: Color {
        Color(podcast.bgColor())
    }

    var tintColor: Color {
        .white
    }

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                PodcastStackView(podcasts: [podcast], geometry: geometry)

                StoryLabelContainer(geometry: geometry) {
                    if NSLocale.isCurrentLanguageEnglish {
                        let time = episode.duration.storyTimeDescription
                        let podcastTitle = podcast.title?.limited(to: 30).nonBreakingSpaces() ?? ""
                        let episodeTitle = episode.title?.limited(to: 30).nonBreakingSpaces().nonBreakingSpaces() ?? ""
                        StoryLabel(L10n.eoyStoryLongestEpisodeTime(time), highlighting: [time], for: .title)
                        StoryLabel(L10n.eoyStoryLongestEpisodeSubtitle(episodeTitle, podcastTitle), highlighting: [episodeTitle, podcastTitle], for: .subtitle)
                            .opacity(0.8)
                    } else {
                        StoryLabel(L10n.eoyStoryLongestEpisode(episode.title ?? "", podcast.title ?? ""), for: .title)
                        StoryLabel(L10n.eoyStoryLongestEpisodeDuration(episode.duration.localizedTimeDescription ?? ""), for: .subtitle)
                            .opacity(0.8)
                    }
                }
            }
        }.background(DynamicBackgroundView(podcast: podcast))
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyStoryLongestEpisodeShareText("%1$@"), episode: episode)
        ]
    }
}

struct LongestEpisodeStory_Previews: PreviewProvider {
    static var previews: some View {
        let episode = Episode()
        episode.title = "Episode title"
        episode.duration = 3600
        return LongestEpisodeStory(episode: episode, podcast: Podcast.previewPodcast())
    }
}
