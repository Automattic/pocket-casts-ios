import SwiftUI
import PocketCastsDataModel

struct LongestEpisode2024Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: 0.8, animation: Animation.spring(_:))

    var identifier: String = "longest_episode"

    let episode: Episode

    let podcast: Podcast

    @State var firstCover: Double = 0.4
    @State var secondCover: Double = 0.32
    @State var thirdCover: Double = 0.24
    @State var fourthCover: Double = 0.16
    @State var fifthCover: Double = 0.08
    @State var sixthCover: Double = 0

    private let backgroundColor = Color(hex: "#E0EFAD")
    private let foregroundColor = Color.black

    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height <= 600
            let timeString = episode.playedUpTo.storyTimeDescriptionForSharing
            VStack(alignment: .leading) {
                Spacer()
                ZStack {
                    covers()
                    let stickerSize = CGSize(width: 194, height: 135)
                    Image("playback-sticker-phew")
                        .resizable()
                        .frame(width: stickerSize.width, height: stickerSize.height)
                        .position(x: -6, y: 0, for: stickerSize, in: geometry.frame(in: .global), corner: .topTrailing)
                }
                .frame(width: geometry.size.width * 0.9)
                .padding(.top, isSmallScreen ? 0 : 20)
                StoryFooter2024(title: L10n.playback2024LongestEpisodeTitle(timeString),
                                description: L10n.playback2024LongestEpisodeDescription(episode.title ?? "unknown", podcast.title ?? "unknown"))
            }
        }
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .onAppear {
            if animated {
                setInitialCoverOffsetForAnimation()
                animationViewModel.play()
            }
        }
    }

    @ViewBuilder func covers() -> some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                ZStack {
                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                        .offset(x: -geometry.size.width * firstCover, y: geometry.size.width * firstCover)
                        .modifier(animationViewModel.animate($firstCover, to: 0.4))

                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.55, height: geometry.size.width * 0.55)
                        .offset(x: -geometry.size.width * secondCover, y: geometry.size.width * secondCover)
                        .modifier(animationViewModel.animate($secondCover, to: 0.32))

                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(x: -geometry.size.width * thirdCover, y: geometry.size.width * thirdCover)
                        .modifier(animationViewModel.animate($thirdCover, to: 0.24))

                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.65, height: geometry.size.width * 0.65)
                        .offset(x: -geometry.size.width * fourthCover, y: geometry.size.width * fourthCover)
                        .modifier(animationViewModel.animate($fourthCover, to: 0.16))

                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                        .offset(x: -geometry.size.width * fifthCover, y: geometry.size.width * fifthCover)
                        .modifier(animationViewModel.animate($fifthCover, to: 0.08))

                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                        .offset(x: -geometry.size.width * sixthCover, y: geometry.size.width * sixthCover)
                        .modifier(animationViewModel.animate($sixthCover, to: 0))
                }
                .offset(x: geometry.size.width * 0.04, y: geometry.size.height * 0.09)
            }
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func onPause() {
        animationViewModel.pause()
    }

    func onResume() {
        animationViewModel.play()
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyStoryLongestEpisodeShareText("%1$@"), episode: episode, year: .y2024)
        ]
    }

    private func setInitialCoverOffsetForAnimation() {
        firstCover = 0.8
        secondCover = 0.8
        thirdCover = 0.8
        fourthCover = 0.8
        fifthCover = 0.8
        sixthCover = 0.8
    }
}
