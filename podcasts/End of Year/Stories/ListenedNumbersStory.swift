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
            ZStack {
                DynamicBackgroundView(podcast: podcasts[safe: 3] ?? podcasts[0])

                VStack {
                    ZStack {
                        podcastCover(5)
                            .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                            .padding(.leading, (geometry.size.width / 2))
                            .padding(.top, -(geometry.size.width / 3))

                        podcastCover(4)
                            .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                            .padding(.leading, -(geometry.size.width / 2.1))
                            .padding(.top, (geometry.size.width / 1.3))

                        podcastCover(0)
                            .frame(width: geometry.size.width * 0.31, height: geometry.size.width * 0.31)
                            .padding(.leading, -(geometry.size.width / 2))
                            .padding(.top, -(geometry.size.width / 3.5))

                        podcastCover(2)
                            .frame(width: geometry.size.width * 0.30, height: geometry.size.width * 0.30)
                            .padding(.leading, (geometry.size.width / 1.8))
                            .padding(.top, (geometry.size.width / 1.5))

                        podcastCover(1)
                            .frame(width: geometry.size.width * 0.37, height: geometry.size.width * 0.37)
                            .padding(.leading, (geometry.size.width / 4.5))
                            .padding(.top, (geometry.size.width / 3))

                        podcastCover(3)
                            .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                            .padding(.leading, -(geometry.size.width / 4))
                    }
                    .modifier(PodcastCoverPerspective())
                    .position(x: geometry.frame(in: .local).midX, y: geometry.size.height * 0.30)

                    Spacer()
                }

                VStack {
                    Spacer()

                    StoryLabel(L10n.eoyStoryListenedToNumbers("\n\(listenedNumbers.numberOfPodcasts)", "\(listenedNumbers.numberOfEpisodes)"))
                        .font(.system(size: 25, weight: .heavy))
                        .frame(maxHeight: geometry.size.height * 0.12)
                        .minimumScaleFactor(0.01)

                    StoryLabel(L10n.eoyStoryListenedToNumbersSubtitle)
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxHeight: geometry.size.height * 0.07)
                        .minimumScaleFactor(0.01)
                        .opacity(renderForSharing ? 0.0 : 0.8)
                        .padding(.bottom, geometry.size.height * 0.18)
                }
                .padding(.trailing, 40)
                .padding(.leading, 40)
            }
        }
    }

    @ViewBuilder
    func podcastCover(_ index: Int) -> some View {
        let podcast = podcasts[safe: index] ?? podcasts[0]
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
