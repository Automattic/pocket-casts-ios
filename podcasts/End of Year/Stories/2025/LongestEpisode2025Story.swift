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

    var body: some View {
        VStack(alignment: .center) {
            headerView
            Spacer()
                .frame(height: 80)
            PodcastCover(podcastUuid: podcast.uuid)
                .frame(width: 196, height: 196)
            Spacer()
            StoryFooter2025(description: L10n.playback2024LongestEpisodeDescription(episode.title ?? "unknown", podcast.title ?? "unknown"))
            Spacer()
                .frame(height: 40)
        }
        .background {
            LottieView(animation: .named("2025_longest_episode"))
                .configure({ animationView in
                    animationView.contentMode = .scaleAspectFill
                })
                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                .scaledToFill()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
    }

    @ViewBuilder var headerView: some View {
        let timeString = episode.playedUpTo.storyTimeDescriptionForSharing
        StoryHeader2025(
            title: "Your marathon listen: \(timeString)",
            description: "Hope you stretched first!"
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
