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
            ZStack {
                DynamicBackgroundView(podcast: podcast)

                VStack {
                    VStack {
                        ZStack {
                            let size = geometry.size.width * 0.60
                            Rectangle().frame(width: size, height: size)
                                .foregroundColor(ColorManager.darkThemeTintForPodcast(podcast).color)
                                .modifier(BigCoverShadow())
                                .modifier(PodcastCoverPerspective())
                                .padding(.top, (size * 0.6))

                            Rectangle().frame(width: size, height: size)
                                .foregroundColor(ColorManager.lightThemeTintForPodcast(podcast).color)
                                .modifier(BigCoverShadow())
                                .modifier(PodcastCoverPerspective())
                                .padding(.top, (size * 0.30))

                            PodcastCover(podcastUuid: podcast.uuid, big: true)
                                .frame(width: size, height: size)
                                .modifier(PodcastCoverPerspective())
                        }

                        StoryLabel(L10n.eoyStoryLongestEpisode(episode.title ?? "", podcast.title ?? ""))
                            .font(.system(size: 25, weight: .heavy))
                            .frame(maxHeight: geometry.size.height * 0.12)
                            .minimumScaleFactor(0.01)
                            .padding(.top)
                        StoryLabel(L10n.eoyStoryLongestEpisodeDuration(episode.duration.storyTimeDescription))
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxHeight: geometry.size.height * 0.07)
                            .minimumScaleFactor(0.01)
                            .opacity(0.8)
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 40)
                }
            }
            .padding(.top, -(geometry.size.height * 0.15))
        }
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
