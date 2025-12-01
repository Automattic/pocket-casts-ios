import SwiftUI
import PocketCastsDataModel
import Lottie

struct LongestEpisode2025Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    var identifier: String = "longest_episode"

    let episode: Episode

    let podcast: Podcast

    private let backgroundColor = Color(hex: "#17423B")
    private let foregroundColor = Color.white
    private let imageSize: CGFloat = UIScreen.isSmallScreen ? 180 : 196
    private let portionFactor: CGFloat = UIScreen.isSmallScreen ? 3.5 : 3.0

    @State private var imageScale = CGFloat(1.1)
    @State private var isAnimating: Bool = true

    private let scaleAnimation: Animation = .timingCurve(0.18, 0.00, 0.08, 1.00, duration: 1.25)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(alignment: .center, spacing: 0) {
                    headerView
                    Spacer()
                        .frame(height: 40)
                    ZStack(alignment: .center) {
                        PodcastImage(uuid: podcast.uuid, size: .page, aspectRatio: nil, contentMode: .fill)
                            .frame(width: imageSize * imageScale, height: imageSize * imageScale)
                            .cornerRadius(4)
                            .background {
                                background(size: proxy.size)
                                    .padding(.top, 20)
                            }
                    }.border(.red)
                    Spacer()
                    footerView
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .onAppear {
            withAnimation(scaleAnimation) {
                self.imageScale = 1.0
            }
        }
        .onDisappear {
            withAnimation(scaleAnimation) {
                self.imageScale = 1.1
            }
        }
    }

    @ViewBuilder var headerView: some View {
        let timeString = episode.playedUpTo.storyTimeDescriptionForSharing
        StoryHeader2025(
            title: L10n.playback2025LongestEpisodeTitle(timeString),
            description: L10n.playback2025LongestEpisodeMessage
        )
    }

    @ViewBuilder var footerView: some View {
        let episode = episode.title ?? "unknown"
        let podcast = podcast.title ?? "unknown"
        StoryFooter2025(
            description: L10n.playback2025LongestEpisodeFooter(episode, podcast)
        )
    }

    @ViewBuilder func background(size: CGSize) -> some View {
        LottieView(animation: .named("2025_longest_episode"))
            .configure({ animationView in
                animationView.contentMode = .scaleAspectFill
            })
            .playbackMode(renderForSharing ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
            .frame(width: size.width, height: size.width)
            .scaleEffect(UIScreen.isSmallScreen ? 1.2 : 1.4)
            .scaledToFill()
//            .padding(.top, 40.0)
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
            StoryShareableText(L10n.eoyStoryLongestEpisodeShareText("%1$@"), episode: episode, year: .y2025)
        ]
    }
}

#Preview {
    LongestEpisode2025Story(
        episode: LongestEpisode2025Story.mockEpisode(),
        podcast: LongestEpisode2025Story.mockPodcast()
    )
}

extension LongestEpisode2025Story {
    fileprivate static func mockEpisode() -> Episode {
        let episode = Episode()
        episode.title = "Why Conservatives Can’t Stop Talking About Aristotle"
        episode.playedUpTo = 300000
        return episode
    }

    fileprivate static func mockPodcast() -> Podcast {
        let podcast = Podcast()
        podcast.title = "Radio Atlantic"
        return podcast
    }
}
