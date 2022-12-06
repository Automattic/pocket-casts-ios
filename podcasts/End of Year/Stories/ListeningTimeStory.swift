import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct ListeningTimeStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "listening_time"

    let listeningTime: Double

    let podcasts: [Podcast]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                StoryLabelContainer(topPadding: geometry.size.height * Constants.topPadding, geometry: geometry) {
                    let time = listeningTime.storyTimeDescription
                    if NSLocale.isCurrentLanguageEnglish {
                        StoryLabel(L10n.eoyStoryListenedToUpdated("\n\(time)\n"), highlighting: [time], for: .title)
                    } else {
                        StoryLabel(L10n.eoyStoryListenedTo("\n\(time)\n"), highlighting: [time], for: .title)
                    }
                    StoryLabel(FunMessage.timeSecsToFunnyText(listeningTime), for: .subtitle)
                        .opacity(0.8)
                }

                // Podcast images angled to fill the width of the view
                let size = 0.30 * geometry.size.height

                HStack(spacing: 20) {
                    ForEach(Constants.displayedPodcasts, id: \.self) {
                        podcastCover($0, size: size)
                    }
                }
                .applyPodcastCoverPerspective()
                .padding(.top)
            }.frame(width: geometry.size.width)
        }.background(DynamicBackgroundView(podcast: podcasts[0]))
    }

    @ViewBuilder
    func podcastCover(_ index: Int, size: Double) -> some View {
        let podcast = podcasts[safe: index] ?? podcasts[0]
        PodcastCover(podcastUuid: podcast.uuid)
            .frame(width: size, height: size)
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
            StoryShareableText(L10n.eoyStoryListenedToShareText(listeningTime.storyTimeDescriptionForSharing))
        ]
    }

    private enum Constants {
        /// The podcasts that are displayed on the view, the middle is your top 10 podcast
        static let displayedPodcasts = [1, 0, 2]
        static let coverSize = 180.0

        static let spaceBetweenLabels = 22.0
        static let labelHorizontalPadding = 35.0

        /// Top padding is a percent calculated using the height of the view
        static let topPadding = 0.158
    }
}

/// Always return the same funny message
struct FunMessage {
    static var message: String?

    static func timeSecsToFunnyText(_ timeInSeconds: Double) -> String {
        guard let message = Self.message else {
            Self.message = FunnyTimeConverter.timeSecsToFunnyText(timeInSeconds)
            return Self.message ?? ""
        }

        return message
    }
}

struct ListeningTimeStory_Previews: PreviewProvider {
    static var previews: some View {
        ListeningTimeStory(listeningTime: 100, podcasts: [Podcast.previewPodcast(), Podcast.previewPodcast(), Podcast.previewPodcast()])
    }
}
