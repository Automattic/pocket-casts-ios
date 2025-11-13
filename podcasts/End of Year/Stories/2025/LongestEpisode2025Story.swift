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

    @State private var imageScale = CGFloat(1.1)
    @State private var isAnimating: Bool = true

    private let scaleAnimation: Animation = .timingCurve(0.18, 0.00, 0.08, 1.00, duration: 1.25)

    var body: some View {
        VStack(alignment: .center) {
            headerView
            Spacer()
                .frame(height: 80)
            PodcastImage(uuid: podcast.uuid, size: .page, aspectRatio: nil, contentMode: .fill)
                .frame(width: 196, height: 196)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .scaleEffect(renderForSharing ? 1 : imageScale)
                .if(isAnimating) {
                    $0.animation(scaleAnimation, value: imageScale)
                }
            VStack {
                Spacer()
                footerView
                Spacer()
            }
        }
        .background {
            LottieView(animation: .named("2025_longest_episode"))
                .configure({ animationView in
                    animationView.contentMode = .scaleAspectFill
                })
                .playbackMode(renderForSharing ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                .scaledToFill()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .onAppear {
            self.isAnimating = true
            self.imageScale = 1.0
        }
        .onDisappear {
            self.isAnimating = false
            self.imageScale = 1.1
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
