import SwiftUI
import PocketCastsDataModel
import Lottie

struct NumberListened2025: ShareableStory {

    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: EndOfYear.defaultDuration)

    let listenedNumbers: ListenedNumbers
    let podcasts: [Podcast]

    @State var topRowXOffset: Double = 0
    @State var bottomRowXOffset: Double = 0

    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background
    let identifier: String = "number_of_shows"

    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                headerView
                podcastsAnimation
                Spacer()
            }
            .foregroundStyle(foregroundColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LottieView(animation: .named("playback_2025_listened"))
                .animationDidFinish({ completed in
                })
                .configure({ animationView in
                    animationView.contentMode = .scaleToFill
                })
                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                .scaledToFill()
                .scaleEffect(1.5)
                .ignoresSafeArea()
        )
        .ignoresSafeArea()
        .background(backgroundColor)
    }

    @ViewBuilder var headerView: some View {
        StoryHeader2025(title: L10n.playback2025ListenedToNumbers(listenedNumbers.numberOfPodcasts, listenedNumbers.numberOfEpisodes))
    }

    @ViewBuilder var podcastsAnimation: some View {
        ZStack() {
            let itemsCount = 7
            let indices = (0..<itemsCount).map { ($0 % itemsCount) % podcasts.endIndex }
            ForEach(Array(zip(indices.indices, indices)), id: \.0) { (index, pos) in
                podcastCover(pos, shadow: false)
                    .frame(width: 260 - CGFloat(index * 20), height: 260 - CGFloat(index * 20))
                    .offset(x: 0, y: ((index % 2) == 0 ? 1 : -1) * CGFloat(index * 20))
                    .zIndex(Double(itemsCount - index))
            }
        }
        .background(.red)
        .onAppear {
            if animated {
                animationViewModel.play()
            }
        }
    }

    @ViewBuilder
    func podcastCover(_ index: Int, shadow: Bool) -> some View {
        let podcast = podcasts[safe: index] ?? podcasts[safe: index % 2 == 0 ? 0 : 1] ?? podcasts[0]
        PodcastImage(uuid: podcast.uuid, size: .grid)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .modify {
                if shadow {
                    $0.shadow(color: Color.black.opacity(0.2), radius: 75, x: 0, y: 2.5)
                } else {
                    $0
                }
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
            StoryShareableText(L10n.eoyStoryListenedToNumbersShareText(listenedNumbers.numberOfPodcasts, listenedNumbers.numberOfEpisodes), year: .y2025)
        ]
    }
}
