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
                VStack(spacing: Constants.spaceBetweenLabels) {
                    StoryLabel(L10n.eoyStoryListenedTo("\n\(listeningTime.localizedTimeDescriptionFullUnits ?? "")"))
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))

                    StoryLabel(FunMessage.timeSecsToFunnyText(listeningTime))
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .regular))
                        .opacity(0.8)
                }
                .padding([.leading, .trailing], Constants.labelHorizontalPadding)
                .padding(.top, geometry.size.height * Constants.topPadding)

                // Podcast images angled to fill the width of the view
                HStack {
                    ForEach(Constants.displayedPodcasts, id: \.self) {
                        podcastCover($0)
                    }
                }
                .padding(.top)
                .modifier(PodcastCoverPerspective(scaleAnchor: .bottom))
            }.frame(width: geometry.size.width)
        }.background(DynamicBackgroundView(podcast: podcasts[0]))
    }

    @ViewBuilder
    func podcastCover(_ index: Int) -> some View {
        let podcast = podcasts[safe: index] ?? podcasts[0]
        PodcastCover(podcastUuid: podcast.uuid)
            .frame(width: Constants.coverSize, height: Constants.coverSize)
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
            StoryShareableText(L10n.eoyStoryListenedToShareText(listeningTime.localizedTimeDescriptionFullUnits ?? ""))
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

/// Apply a perspective to the podcasts cover
struct PodcastCoverPerspective: ViewModifier {

    /// Allows overriding of the scaleEffect anchor property, defaults to .center
    let scaleAnchor: UnitPoint

    init(scaleAnchor: UnitPoint = .center) {
        self.scaleAnchor = scaleAnchor
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: -45), anchor: .center)
            .scaleEffect(x: 1.0, y: 0.5, anchor: scaleAnchor)
    }
}

struct ListeningTimeStory_Previews: PreviewProvider {
    static var previews: some View {
        ListeningTimeStory(listeningTime: 100, podcasts: [Podcast.previewPodcast(), Podcast.previewPodcast(), Podcast.previewPodcast()])
    }
}
