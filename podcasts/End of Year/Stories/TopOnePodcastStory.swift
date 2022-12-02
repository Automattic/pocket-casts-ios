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
        let podcast = topPodcast.podcast
        GeometryReader { geometry in
            VStack {
                PodcastStackView(podcasts: [podcast], geometry: geometry)

                StoryLabelContainer {
                    let title = podcast.title ?? ""
                    let author = podcast.author ?? ""
                    StoryLabel(L10n.eoyStoryTopPodcast("\n" + title, author), highlighting: [title, author], for: .title)
                    StoryLabel(L10n.eoyStoryTopPodcastSubtitle(topPodcast.numberOfPlayedEpisodes, topPodcast.totalPlayedTime.storyTimeDescription), for: .subtitle)
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
            StoryShareableText(L10n.eoyStoryTopPodcastShareText("%1$@"), podcast: topPodcast.podcast)
        ]
    }
}

struct TopOnePodcastStory_Previews: PreviewProvider {
    static var previews: some View {
        TopOnePodcastStory(topPodcast: TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600))
    }
}
