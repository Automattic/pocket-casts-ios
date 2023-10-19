import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct TopFivePodcastsStory: ShareableStory {
    let topPodcasts: [TopPodcast]

    let identifier: String = "top_five_podcast"

    let duration: TimeInterval = 5.seconds

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    StoryLabel(L10n.eoyStoryTopPodcastsTitle, for: .title, geometry: geometry)
                    StoryLabel(L10n.eoyStoryTopPodcastsSubtitle, for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }

                let headerSpacing = geometry.size.height * 0.054
                let size = round(geometry.size.height * 0.09)

                VStack(spacing: geometry.size.height * 0.03) {
                    ForEach(0...4, id: \.self) {
                        topPodcastRow($0, size: size, geometry: geometry)
                    }
                }
                .padding([.leading, .trailing], 35)
                .padding(.top, headerSpacing)
            }.background(
                ZStack(alignment: .bottom) {
                    Color.black

                    StoryGradient()
                    .offset(x: geometry.size.width * 0.7, y: -geometry.size.height * 0.7)
                }
            )
        }
    }

    @ViewBuilder
    func topPodcastRow(_ index: Int, size: Double, geometry: GeometryProxy) -> some View {
        HStack(spacing: 16) {
            Text("\(index + 1)")
                .font(.custom("DM Sans", size: geometry.size.height * 0.025))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "8F97A4"))
                .frame(width: size * 0.2)

                if let podcast = topPodcasts[safe: index]?.podcast {
                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: size, height: size)
                } else {
                    Rectangle()
                        .frame(width: size, height: size)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(topPodcasts[safe: index]?.podcast.title ?? "")
                    .font(.custom("DM Sans", size: geometry.size.height * 0.024))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(topPodcasts[safe: index]?.totalPlayedTime.storyTimeDescription ?? "")
                    .font(.custom("DM Sans", size: geometry.size.height * 0.018))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "8F97A4"))
                    .lineLimit(2)
                    .opacity(0.8)
            }
            // Allow the the title label to expand based on the size of the row
            // Show more text for larger devices, and a bit less for smaller ones
            .frame(maxHeight: size)
            Spacer()
        }
        .opacity(topPodcasts[safe: index]?.podcast != nil ? 1 : 0)
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
            StoryShareableText(L10n.eoyStoryTopPodcastsShareText("%1$@"), podcasts: topPodcasts.map { $0.podcast })
        ]
    }
}

struct DummyStory_Previews: PreviewProvider {
    static var previews: some View {
        TopFivePodcastsStory(topPodcasts: [TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600), TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600), TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600), TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600), TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600)])
    }
}
