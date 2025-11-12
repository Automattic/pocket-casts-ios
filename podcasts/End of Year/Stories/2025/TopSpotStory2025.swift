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
            GeometryReader { proxy in
                VStack(alignment: .center, spacing: 24) {
                    StoryHeader2025(title: L10n.playback2025TopSpotTitle, description: L10n.playback2025TopSpotSubtitle)
                    ZStack {
                        LottieView(animation: .named("playback_2025_top_spot_story"))
                            .animationDidFinish({ completed in
                            })
                            .configure({ animationView in
                                animationView.contentMode = .scaleToFill
                            })
                            .playbackMode(renderForSharing ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                            .frame(width: proxy.size.width, height: proxy.size.width)
                            .scaleEffect(1.2)
                            .scaledToFill()
                        PodcastImage(uuid: topPodcast.podcast.uuid, size: .page, aspectRatio: nil, contentMode: .fill)
                            .frame(width: proxy.size.width * scaleFactor, height: proxy.size.width * scaleFactor)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }                    
                    VStack {
                        let timeString = topPodcast.totalPlayedTime.storyTimeDescriptionForSharing
                        let numberPlayed = topPodcast.numberOfPlayedEpisodes
                        StoryFooter2025(title: nil, description: L10n.playback2025TopSpotDescription(numberPlayed, timeString))
                    }
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
