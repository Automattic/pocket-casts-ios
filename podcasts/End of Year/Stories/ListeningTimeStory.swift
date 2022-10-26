import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct ListeningTimeStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let listeningTime: Double

    let podcasts: [Podcast]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(podcast: podcasts[0])

                VStack {
                    Text(L10n.eoyStoryListenedTo(listeningTime.localizedTimeDescription ?? ""))
                        .foregroundColor(.white)
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.12)
                        .minimumScaleFactor(0.01)

                    Text(FunnyTimeConverter.timeSecsToFunnyText(listeningTime))
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

                    GeometryReader { coversGeometry in
                        HStack {
                            leftPodcastCover
                                .frame(width: 140, height: 140)
                                .modifier(PodcastCover())

                            ImageView(ServerHelper.imageUrl(podcastUuid: podcasts[0].uuid, size: 280))
                                .frame(width: 140, height: 140)
                                .modifier(PodcastCover())

                            rightPodcastCover
                                .modifier(PodcastCover())
                                .frame(width: 140, height: 140)
                        }
                        .modifier(PodcastCoverPerspective())
                        .position(x: coversGeometry.size.width / 2, y: geometry.size.height - 230)
                    }
                }
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
    var leftPodcastCover: some View {
        if let podcast = podcasts[safe: 1] {
            ImageView(ServerHelper.imageUrl(podcastUuid: podcast.uuid, size: 280))
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    var rightPodcastCover: some View {
        if let podcast = podcasts[safe: 2] {
            ImageView(ServerHelper.imageUrl(podcastUuid: podcast.uuid, size: 280))
        } else {
            EmptyView()
        }
    }
}

/// Apply a perspective to the podcasts cover
struct PodcastCoverPerspective: ViewModifier {
    private var transform: CGAffineTransform {
        let values: [CGFloat] = [0.89, 0, 0.58, 1, 0, 0]
        return CGAffineTransform(
            a: values[0], b: values[1],
            c: values[2], d: values[3],
            tx: 0, ty: 0
        )
    }

    func body(content: Content) -> some View {
        content
            .transformEffect(transform)
            .rotationEffect(.init(degrees: -30))
    }
}

/// Apply shadow and radius to podcast cover
struct PodcastCover: ViewModifier {
    func body(content: Content) -> some View {
        content
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(4)
            .shadow(radius: 2, x: 0, y: 1)
            .accessibilityHidden(true)
    }
}

struct ListeningTimeStory_Previews: PreviewProvider {
    static var previews: some View {
        ListeningTimeStory(listeningTime: 100, podcasts: [Podcast.previewPodcast(), Podcast.previewPodcast(), Podcast.previewPodcast()])
    }
}
