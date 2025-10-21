import SwiftUI
import PocketCastsDataModel
import Lottie
import Combine

class StepCounter: ObservableObject {

    private let interval: Double
    private var timer: Timer?

    @Published var counter: Int = 0

    init(interval: TimeInterval) {
        self.interval = interval
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            counter = counter + 1
        }
    }
}

struct NumberListened2025: ShareableStory {

    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: EndOfYear.defaultDuration)

    @StateObject private var stepCounter: StepCounter = .init(interval: 2)

    let listenedNumbers: ListenedNumbers
    let podcasts: [Podcast]

    @State var progress = CGFloat(0)

    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background
    let identifier: String = "number_of_shows"

    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                headerView
                Spacer()
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

    let itemsCount = 7

    var indices: [Int] {
        let indices = (0..<itemsCount).map { (stepCounter.counter + $0) % podcasts.endIndex }
        return indices
    }

    @ViewBuilder var podcastsAnimation: some View {
        ZStack() {
            ForEach(Array(zip(indices.indices, indices)), id: \.0) { (index, pos) in
                let shift = index - 3
                let size = 260 - CGFloat(abs(shift) * 30)
                let offset = CGFloat(shift * 30)
                podcastCover(pos, shadow: false)
                    .frame(width: size * (1.0 - (0.1 * progress)), height: size * (1.0 - (0.1 * progress)))
                    .offset(x: 0, y: offset - (5.0 * progress))
                    .zIndex(Double(itemsCount - abs(shift)))                    
            }
        }
        .frame(width: 320, height: 320)
        .background(.red)
        .onAppear {
            if animated {
                animationViewModel.play()
            }
        }
        .onChange(of: stepCounter.counter) { value in
            progress = 0
            withAnimation {
                progress = 1
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
