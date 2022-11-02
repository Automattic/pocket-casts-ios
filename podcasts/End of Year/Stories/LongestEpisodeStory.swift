import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct LongestEpisodeStory: StoryView {
    let duration: TimeInterval = 5.seconds

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
                            let size = geometry.size.width * 0.45
                            Rectangle().frame(width: size, height: size)
                                .foregroundColor(ColorManager.darkThemeTintForPodcast(podcast).color)
                                .modifier(PodcastCover())
                                .modifier(PodcastCoverPerspective())
                                .padding(.leading, -60)
                                .padding(.top, (size * 0.7))

                            Rectangle().frame(width: size, height: size)
                                .foregroundColor(ColorManager.lightThemeTintForPodcast(podcast).color)
                                .modifier(PodcastCover())
                                .modifier(PodcastCoverPerspective())
                                .padding(.leading, -60)
                                .padding(.top, (size * 0.35))

                            ImageView(ServerHelper.imageUrl(podcastUuid: podcast.uuid, size: 280))
                                .frame(width: size, height: size)
                                .modifier(PodcastCover())
                                .modifier(PodcastCoverPerspective())
                                .padding(.leading, -60)
                        }

                        Text(L10n.eoyStoryLongestEpisode(episode.title ?? "", podcast.title ?? ""))
                            .foregroundColor(.white)
                            .font(.system(size: 25, weight: .heavy))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: geometry.size.height * 0.12)
                            .minimumScaleFactor(0.01)
                            .padding(.top)
                        Text(L10n.eoyStoryLongestEpisodeDuration(episode.duration.localizedTimeDescription ?? ""))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: geometry.size.height * 0.07)
                            .minimumScaleFactor(0.01)
                            .opacity(0.8)
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 40)
                }
            }
            .padding(.top, -(0.05 * geometry.size.height))

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("logo_white")
                        .padding(.bottom, 40)
                    Spacer()
                }
            }
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: .longestEpisode)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: .longestEpisode)
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
