import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct ListenedNumbersStory: StoryView {
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
                            .frame(width: geometry.size.width * 0.17, height: geometry.size.width * 0.17)
                            .padding(.leading, (geometry.size.width / 3.8))
                            .padding(.top, -(geometry.size.width / 3.8))

                        podcastCover(4)
                            .frame(width: geometry.size.width * 0.17, height: geometry.size.width * 0.17)
                            .padding(.leading, -(geometry.size.width / 2.3))
                            .padding(.top, (geometry.size.width / 1.7))

                        podcastCover(0)
                            .frame(width: geometry.size.width * 0.23, height: geometry.size.width * 0.23)
                            .padding(.leading, -(geometry.size.width / 2))
                            .padding(.top, -(geometry.size.width / 3.5))

                        podcastCover(2)
                            .frame(width: geometry.size.width * 0.22, height: geometry.size.width * 0.22)
                            .padding(.leading, (geometry.size.width / 3))
                            .padding(.top, (geometry.size.width / 1.5))

                        podcastCover(1)
                            .frame(width: geometry.size.width * 0.29, height: geometry.size.width * 0.29)
                            .padding(.top, (geometry.size.width / 3))

                        podcastCover(3)
                            .frame(width: geometry.size.width * 0.27, height: geometry.size.width * 0.27)
                            .padding(.leading, -(geometry.size.width / 3))
                    }
                    .modifier(PodcastCoverPerspective())
                    .padding(.leading, -(geometry.size.width * 0.2))
                    .padding(.top, geometry.size.width * 0.08)

                    Spacer()
                }

                VStack {
                    Spacer()

                    Text(L10n.eoyStoryListenedToNumbers("\(listenedNumbers.numberOfPodcasts)", "\(listenedNumbers.numberOfEpisodes)"))
                        .foregroundColor(.white)
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.12)
                        .minimumScaleFactor(0.01)

                    Text(L10n.eoyStoryListenedToNumbersSubtitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.07)
                        .minimumScaleFactor(0.01)
                        .opacity(0.8)
                        .padding(.bottom, geometry.size.height * 0.18)
                }
                .padding(.trailing, 40)
                .padding(.leading, 40)
            }

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
