import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct ListenedNumbersStory: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool

    var duration: TimeInterval = 5.seconds

    let identifier: String = "number_of_podcasts_and_episodes_listened"

    let listenedNumbers: ListenedNumbers

    let podcasts: [Podcast]

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    StoryLabel(L10n.eoyStoryListenedToNumbers("\n\(listenedNumbers.numberOfPodcasts)", "\(listenedNumbers.numberOfEpisodes)"), for: .title, geometry: geometry)
                    StoryLabel(L10n.eoyStoryListenedToNumbersSubtitle, for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                        .opacity(renderForSharing ? 0.0 : 1)
                }

                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        Group {
                            podcastCover(0)
                            podcastCover(1)
                            podcastCover(2)
                            podcastCover(3)
                            podcastCover(0)
                            podcastCover(1)
                            podcastCover(2)
                            podcastCover(3)
                        }
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)
                    }

                    HStack(spacing: 16) {
                        Group {
                            podcastCover(4)
                            podcastCover(5)
                            podcastCover(6)
                            podcastCover(7)
                            podcastCover(4)
                            podcastCover(5)
                            podcastCover(6)
                            podcastCover(7)
                        }
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)
                    }
                    .padding(.leading, geometry.size.width * 0.35)
                }
                .rotationEffect(Angle(degrees: -15))
                .padding(.top, geometry.size.height * 0.1)
            }
            .background(
                ZStack(alignment: .bottom) {
                    Color.black

                    StoryGradient(geometry: geometry)
                    .offset(x: geometry.size.width * 0.4, y: geometry.size.height * 0.25)
                }
            )
        }
    }

    @ViewBuilder
    func podcastCover(_ index: Int) -> some View {
        let podcast = podcasts[safe: index] ?? podcasts[safe: index % 2 == 0 ? 0 : 1] ?? podcasts[0]
        PodcastCover(podcastUuid: podcast.uuid)
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
            StoryShareableText(L10n.eoyStoryListenedToNumbersShareText(listenedNumbers.numberOfPodcasts, listenedNumbers.numberOfEpisodes))
        ]
    }
}

struct ListenedNumbersStory_Previews: PreviewProvider {
    static var previews: some View {
        ListenedNumbersStory(listenedNumbers: ListenedNumbers(numberOfPodcasts: 5, numberOfEpisodes: 10), podcasts: [Podcast.previewPodcast()])
    }
}
