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
    }

    deinit {
        self.timer?.invalidate()
    }

    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            counter = counter + 1
        }
    }
}

struct NumberListened2025: ShareableStory {

    private enum Constants {
        static let speed: Double = 1.3
        static let yOffset: CGFloat = 30
        static let xOffset: CGFloat = 26
        static let coverSize: CGFloat = 260
        static let animationSize: CGFloat = Self.coverSize + (2 * Self.yOffset)
    }

    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: EndOfYear.defaultDuration)

    @StateObject private var stepCounter: StepCounter = .init(interval: Constants.speed)

    let listenedNumbers: ListenedNumbers
    let podcasts: [Podcast]

    @State var progress = CGFloat(0)

    @State var zChange: Double = 0

    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background
    let identifier: String = "number_of_shows"

    var body: some View {
        GeometryReader { proxy in
            let safeBottom = proxy.safeAreaInsets.bottom
            VStack(alignment: .center) {
                headerView
                Spacer()
                podcastsAnimation
                Spacer()
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .padding(.bottom, safeBottom)
        }
        .background(content: {
            LottieView(animation: .named("playback_2025_listened"))
                .animationDidFinish({ completed in
                })
                .configure({ animationView in
                    animationView.contentMode = .scaleToFill
                })
                .playbackMode(renderForSharing ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                .scaledToFill()
                .scaleEffect(1.1)
                .ignoresSafeArea()
        }
        )
        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
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

    func calculateDimensions(for index: Int) -> (CGFloat, CGFloat, Double, CGFloat) {
        let shift: CGFloat = CGFloat(index - 3)
        let direction: CGFloat = shift <= 0 ? -1 : 1
        let size: CGFloat = Constants.coverSize - CGFloat(abs(shift) * Constants.xOffset)
        let offset: CGFloat = CGFloat(shift * Constants.yOffset)
        let zOffset: Double = Double(CGFloat(itemsCount) - abs(shift))
        return (size, offset, zOffset, direction)
    }

    @ViewBuilder var podcastsAnimation: some View {
        ZStack() {
            ForEach(Array(zip(indices.indices, indices)), id: \.0) { (index, pos) in
                let result = calculateDimensions(for: index)
                podcastCover(pos, shadow: true)
                    .frame(width: result.0 + (Constants.xOffset * result.3 * progress), height: result.0 + (Constants.xOffset * result.3 * progress))
                    .offset(x: 0, y: result.1 - (Constants.yOffset * progress))
                    .zIndex(result.2 + (index == 4 ? zChange : 0))
                    .opacity((index == 0) ? 1 - progress : ((index == itemsCount - 1) ? progress : 1))
            }
        }
        .frame(width: Constants.animationSize, height: Constants.animationSize)
        .onAppear {
            if animated {
                animationViewModel.play()
                startCoverAnimation()
                stepCounter.start()
            }
        }
        .onChange(of: stepCounter.counter) { value in
            startCoverAnimation()
        }
    }

    func startCoverAnimation() {
        progress = 0
        zChange = 0
        withAnimation(.timingCurve(0.90, 0.00, 0.08, 1.00, duration: Constants.speed)) {
            progress = 1
        }
        // ZIndex changes cannot be animated so we are using this dispach to cause a change of Z index at the middle of the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.speed / 2.0) {
            zChange = 2
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

#Preview {
    NumberListened2025(
        listenedNumbers:
            ListenedNumbers(
                numberOfPodcasts: 1,
                numberOfEpisodes: 100
            ),
        podcasts: [
            Podcast()
        ]
    )
}
