import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct TopOnePodcastStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "top_one_podcast"

    let topPodcast: TopPodcast

    var backgroundColor: Color {
        Color(topPodcast.podcast.bgColor())
    }

    var tintColor: Color {
        .white
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(podcast: topPodcast.podcast)

                VStack {
                    VStack {
                        ZStack {
                            let size = geometry.size.width * 0.60
                            Rectangle().frame(width: size, height: size)
                                .foregroundColor(ColorManager.darkThemeTintForPodcast(topPodcast.podcast).color)
                                .modifier(BigCoverShadow())
                                .modifier(PodcastCoverPerspective())
                                .padding(.top, (size * 0.6))

                            Rectangle().frame(width: size, height: size)
                                .foregroundColor(ColorManager.lightThemeTintForPodcast(topPodcast.podcast).color)
                                .modifier(BigCoverShadow())
                                .modifier(PodcastCoverPerspective())
                                .padding(.top, (size * 0.30))

                            PodcastCover(podcastUuid: topPodcast.podcast.uuid, big: true)
                                .frame(width: size, height: size)
                                .modifier(PodcastCoverPerspective())
                        }

                        StoryLabel(L10n.eoyStoryTopPodcast(topPodcast.podcast.title ?? "", topPodcast.podcast.author ?? ""), for: .title)
                            .frame(maxHeight: geometry.size.height * 0.12)
                            .minimumScaleFactor(0.01)
                        StoryLabel(L10n.eoyStoryTopPodcastSubtitle(topPodcast.numberOfPlayedEpisodes, topPodcast.totalPlayedTime.storyTimeDescription), for: .subtitle)
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
            StoryShareableText(L10n.eoyStoryTopPodcastShareText("%1$@"), podcast: topPodcast.podcast)
        ]
    }
}

struct TopOnePodcastStory_Previews: PreviewProvider {
    static var previews: some View {
        TopOnePodcastStory(topPodcast: TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600))
    }
}
