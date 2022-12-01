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

                VStack {
                    Text(L10n.eoyStoryListenedTo("\n\(listeningTime.localizedTimeDescription ?? "")"))
                        .foregroundColor(.white)
                        .font(.system(size: 25, weight: .heavy))
                    Text(L10n.eoyStoryListenedTo("\n\(listeningTime.localizedTimeDescriptionFullUnits ?? "")"))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.12)
                        .minimumScaleFactor(0.01)

                    Text(FunMessage.timeSecsToFunnyText(listeningTime))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.07)
                        .minimumScaleFactor(0.01)
                        .opacity(0.8)
                    Spacer()
                }
                .padding(.top, geometry.size.height * 0.15)
                .padding(.trailing, 40)
                .padding(.leading, 40)

                VStack {
                    Spacer()

                    HStack {
                        ForEach([1, 0, 2], id: \.self) {
                            podcastCover($0)
                        }
                    }
                    .modifier(PodcastCoverPerspective())
                    .position(x: geometry.frame(in: .local).midX, y: geometry.size.height - 230)
                }
            }
        }.background(DynamicBackgroundView(podcast: podcasts[0]))
    }

    @ViewBuilder
    func podcastCover(_ index: Int) -> some View {
        let podcast = podcasts[safe: index] ?? podcasts[0]
        PodcastCover(podcastUuid: podcast.uuid)
            .frame(width: 180, height: 180)
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
