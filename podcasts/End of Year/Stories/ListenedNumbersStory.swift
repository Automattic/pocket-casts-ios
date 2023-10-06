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
                    if NSLocale.isCurrentLanguageEnglish {
                        let podcasts = L10n.eoyStoryListenedToPodcastText(listenedNumbers.numberOfPodcasts)
                        let episodes = L10n.eoyStoryListenedToEpisodesText(listenedNumbers.numberOfEpisodes)

                        StoryLabel(L10n.eoyStoryListenedToNumbersUpdated("\n" + podcasts + "\n", episodes), highlighting: [podcasts, episodes], for: .title, geometry: geometry)
                        StoryLabel(L10n.eoyStoryListenedToNumbersSubtitleUpdated, for: .subtitle, geometry: geometry)
                            .opacity(renderForSharing ? 0.0 : 0.8)
                    } else {
                        StoryLabel(L10n.eoyStoryListenedToNumbers("\n\(listenedNumbers.numberOfPodcasts)", "\(listenedNumbers.numberOfEpisodes)"), for: .title)
                        StoryLabel(L10n.eoyStoryListenedToNumbersSubtitle, for: .subtitle)
                            .opacity(renderForSharing ? 0.0 : 0.8)
                    }
                }

                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        podcastCover(5)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)

                        podcastCover(4)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)

                        podcastCover(0)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)

                        podcastCover(2)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)
                    }

                    HStack(spacing: 16) {
                        podcastCover(1)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)

                        podcastCover(3)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)

                        podcastCover(6)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)

                        podcastCover(7)
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

                    StoryGradient()
                    .offset(x: geometry.size.width * 0.4, y: geometry.size.height * 0.25)
                }
            )
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

struct StoryGradient: View {
    var body: some View {
        Rectangle()
        .foregroundColor(.clear)
        .frame(width: 510, height: 510)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.61),
                    Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.49, y: 0.11),
                endPoint: UnitPoint(x: 0.49, y: 0.98)
            )
        )
        .cornerRadius(510)
        .blur(radius: 107)
        .opacity(0.6)
    }
}

struct ListenedNumbersStory_Previews: PreviewProvider {
    static var previews: some View {
        ListenedNumbersStory(listenedNumbers: ListenedNumbers(numberOfPodcasts: 5, numberOfEpisodes: 10), podcasts: [Podcast.previewPodcast()])
    }
}
