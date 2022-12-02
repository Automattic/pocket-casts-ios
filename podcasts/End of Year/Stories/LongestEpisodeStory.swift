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
            VStack {
                PodcastStackView(podcasts: [podcast], geometry: geometry)

                StoryLabelContainer {
                    let time = episode.duration.storyTimeDescription
                    let title = podcast.title?.replacingOccurrences(of: " ", with: "\u{00a0}") ?? ""
                    StoryLabel(L10n.eoyStoryLongestEpisodeTime(time), highlighting: [time], for: .title)
                    StoryLabel(L10n.eoyStoryLongestEpisodeFromPodcast(title), highlighting: [title], for: .subtitle)
                        .opacity(0.8)
                }
                Spacer()
            }.frame(width: geometry.size.width).padding(.top, (geometry.size.height * 0.10))
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
