import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct TopOnePodcastStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "top_one_podcast"

    let podcasts: [TopPodcast]

    var topPodcast: TopPodcast {
        podcasts[0]
    }

    var backgroundColor: Color {
        Color(topPodcast.podcast.bgColor())
    }

    var tintColor: Color {
        .white
    }

    var body: some View {
        let podcast = topPodcast.podcast
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    let title = podcast.title ?? ""
                    let author = podcast.author ?? ""
                    StoryLabel(L10n.eoyStoryTopPodcast(title), for: .title, geometry: geometry)

                    let time = topPodcast.totalPlayedTime.storyTimeDescription
                    let count = L10n.eoyStoryListenedToEpisodesText(topPodcast.numberOfPlayedEpisodes)
                    StoryLabel(L10n.eoyStoryTopPodcastSubtitle(topPodcast.numberOfPlayedEpisodes, time), for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }

                ZStack {
                    PodcastCover(podcastUuid: topPodcast.podcast.uuid)
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                }
            }.background(
                ZStack(alignment: .bottom) {
                    Color.black

                    StoryGradient()
                    .offset(x: -geometry.size.width * 0.8, y: geometry.size.height * 0.25)
                }
            )
        }
    }

    @ViewBuilder
    func podcastCover(_ index: Int) -> some View {
        if let topPodcast = podcasts[safe: index] {
            PodcastCover(podcastUuid: topPodcast.podcast.uuid)
        } else {
            EmptyView()
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
        TopOnePodcastStory(podcasts: [TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600)])
    }
}
