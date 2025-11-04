import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils
import Lottie

struct TopSpotStory2025: ShareableStory {

    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let topPodcast: TopPodcast

    private let foregroundColor = Color.white
    private let backgroundColor = Color(hex: "#17423B")
    private var scaleFactor: Double = 0.75

    let identifier: String = "top_1_show"

    init(topPodcast: TopPodcast) {
        self.topPodcast = topPodcast
    }

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                StoryHeader2025(title: L10n.playback2025TopSpotTitle, description: L10n.playback2025TopSpotSubtitle)
                Spacer()
                GeometryReader { proxy in
                    ZStack {
                        if renderForSharing {
                            //TODO: Add correct background image for sharing
                            Image("playback_2025_listening_time_back")
                                .resizable()
                                .scaledToFit()
                        } else {
                            LottieView(animation: .named("playback_2025_top_spot_story"))
                                .animationDidFinish({ completed in
                                })
                                .configure({ animationView in
                                    animationView.contentMode = .scaleToFill
                                })
                                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                                .scaledToFill()
                                .ignoresSafeArea()
                        }
                        PodcastImage(uuid: topPodcast.podcast.uuid, size: .page, aspectRatio: nil, contentMode: .fill)
                            .frame(width: proxy.size.width * scaleFactor, height: proxy.size.width * scaleFactor)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .frame(width: proxy.size.width * 1.25, height: proxy.size.width * 1.25)
                    .offset(x: -proxy.size.width * 0.125, y: 0)
                }
                VStack {
                    Spacer()
                    let timeString = topPodcast.totalPlayedTime.storyTimeDescriptionForSharing
                    let numberPlayed = topPodcast.numberOfPlayedEpisodes
                    StoryHeader2025(title: nil, description: L10n.playback2025TopSpotDescription(numberPlayed, timeString))
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
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
            StoryShareableText(L10n.eoyStoryTopPodcastShareText("%1$@"), podcast: topPodcast.podcast, year: .y2025)
        ]
    }
}
