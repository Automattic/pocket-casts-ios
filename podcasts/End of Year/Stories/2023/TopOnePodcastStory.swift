import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct TopOnePodcastStory: ShareableStory {
    @Environment(\.animated) var animated: Bool

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

    var coverAnimation: Namespace.ID?

    var body: some View {
        let podcast = topPodcast.podcast
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    let title = podcast.title ?? ""
                    StoryLabel(L10n.eoyStoryTopPodcast(title), for: .title, geometry: geometry)

                    let time = topPodcast.totalPlayedTime.storyTimeDescription
                    StoryLabel(L10n.eoyStoryTopPodcastSubtitle(topPodcast.numberOfPlayedEpisodes, time), for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }

                ZStack {
                    podcastCover(1)
                        .if(animated && coverAnimation != nil) { view in
                            view.matchedGeometryEffect(id: "secondCover", in: coverAnimation!)
                        }
                        .frame(width: geometry.size.width * 0.3, height: geometry.size.width * 0.3)
                        .offset(x: -geometry.size.width * 0.53, y: -geometry.size.height * 0.15)
                        .opacity(0.3)

                    podcastCover(2)
                        .if(animated && coverAnimation != nil) { view in
                            view.matchedGeometryEffect(id: "thirdCover", in: coverAnimation!)
                        }
                        .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                        .offset(x: -geometry.size.width * 0.3, y: geometry.size.height * 0.2)
                        .opacity(0.5)

                    podcastCover(3)
                        .if(animated && coverAnimation != nil) { view in
                            view.matchedGeometryEffect(id: "fourthCover", in: coverAnimation!)
                        }
                        .frame(width: geometry.size.width * 0.32, height: geometry.size.width * 0.32)
                        .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.23)
                        .opacity(0.5)

                    podcastCover(4)
                        .if(animated && coverAnimation != nil) { view in
                            view.matchedGeometryEffect(id: "fifthCover", in: coverAnimation!)
                        }
                        .frame(width: geometry.size.width * 0.2, height: geometry.size.width * 0.2)
                        .offset(x: geometry.size.width * 0.4, y: -geometry.size.height * 0.11)
                        .opacity(0.2)

                    PodcastCover(podcastUuid: topPodcast.podcast.uuid, higherQuality: true)
                        .if(animated && coverAnimation != nil) { view in
                            view.matchedGeometryEffect(id: "firstCover", in: coverAnimation!)
                        }
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                }
                .padding(.top, geometry.size.height * 0.09)
            }.background(
                ZStack(alignment: .bottom) {
                    Color.black

                    StoryGradient(geometry: geometry)
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
        TopOnePodcastStory(podcasts: [TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600), TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600)])
    }
}
