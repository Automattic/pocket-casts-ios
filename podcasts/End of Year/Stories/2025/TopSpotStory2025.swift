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
    private var scaleFactor: Double = UIScreen.isSmallScreen ? 0.57 : 0.72
    private var scaleAnimation: Animation = .timingCurve(0.33, 0.00, 0.00, 1.00, duration: 1)

    @State private var backgroundAnimationScale = 1.3
    @State private var coverAnimationScale = 1.05

    let identifier: String = "top_1_show"

    init(topPodcast: TopPodcast) {
        self.topPodcast = topPodcast
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background(size: proxy.size)
                VStack(alignment: .center, spacing: 0) {
                    StoryHeader2025(title: L10n.playback2025TopSpotTitle, description: L10n.playback2025TopSpotSubtitle)
                    Spacer()
                    VStack {
                        Spacer()
                        let timeString = topPodcast.totalPlayedTime.storyTimeDescriptionForSharing
                        let numberPlayed = topPodcast.numberOfPlayedEpisodes
                        StoryFooter2025(title: nil, description: L10n.playback2025TopSpotDescription(numberPlayed, timeString))
                        Spacer()
                    }
                    .frame(height: proxy.size.height / 3)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .onAppear {
            if renderForSharing {
                backgroundAnimationScale = 1.0
                coverAnimationScale = 1.0
            } else {
                withAnimation(scaleAnimation) {
                    backgroundAnimationScale = 1.0
                    coverAnimationScale = 1.0
                }
            }
        }
        .onDisappear {
            backgroundAnimationScale = 1.3
            coverAnimationScale = 1.05
        }
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

    @ViewBuilder func background(size: CGSize) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            ZStack {
                Group {
                    LottieView(animation: .named("playback_2025_top_spot_story"))
                        .animationDidFinish({ completed in
                        })
                        .configure({ animationView in
                            animationView.contentMode = .scaleToFill
                        })
                        .playbackMode(renderForSharing ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                        .frame(width: size.width, height: size.width)
                        .scaleEffect(UIScreen.isSmallScreen ? 1.0 : 1.25)
                        .scaledToFill()
                }
                .scaleEffect(backgroundAnimationScale)
                Group {
                    PodcastImage(uuid: topPodcast.podcast.uuid, size: .page, aspectRatio: nil, contentMode: .fill)
                        .frame(width: size.width * scaleFactor, height: size.width * scaleFactor)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(coverAnimationScale)
            }
            Spacer()
        }
    }
}

#Preview {
    TopSpotStory2025(
        topPodcast: TopPodcast(
            podcast: Podcast(),
            numberOfPlayedEpisodes: 10,
            totalPlayedTime: 100000
        )
    )
}
