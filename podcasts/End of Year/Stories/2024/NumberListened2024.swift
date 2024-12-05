import SwiftUI
import PocketCastsDataModel

struct NumberListened2024: ShareableStory {

    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: EndOfYear.defaultDuration)

    let listenedNumbers: ListenedNumbers
    let podcasts: [Podcast]

    @State var topRowXOffset: Double = 0
    @State var bottomRowXOffset: Double = 0

    private let foregroundColor = Color.black
    private let backgroundColor = Color(hex: "#EFECAD")
    let identifier: String = "number_of_shows"

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            podcastMarquees()
            Spacer()
            footerView()
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
    }

    @ViewBuilder func podcastMarquees() -> some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry, alignment: .center) {
                VStack(spacing: -28) {
                    let scale = 0.48
                    let marqueeItemsCount = 4
                    let topIndices = (0..<4*2).map { ($0 % marqueeItemsCount) % podcasts.endIndex }
                    let bottomIndices = (0..<4*2).map { (($0 + marqueeItemsCount) % (marqueeItemsCount + marqueeItemsCount)) % podcasts.endIndex }
                    podcastMarquee(size: geometry.size, shadow: false, scale: scale * 0.8, indices: topIndices)
                        .offset(x: topRowXOffset)
                        .modifier(animationViewModel.animate($topRowXOffset, to: -300))
                    podcastMarquee(size: geometry.size, shadow: true, scale: scale, indices: bottomIndices)
                        .padding(.leading, geometry.size.width * 0.35)
                        .offset(x: bottomRowXOffset)
                        .modifier(animationViewModel.animate($bottomRowXOffset, to: 300))
                }
                .rotationEffect(Angle(degrees: -15))
            }
            .onAppear {
                if animated {
                    animationViewModel.play()
                }
            }
        }
    }

    @ViewBuilder func podcastMarquee(size: CGSize, shadow: Bool, scale: Double, indices: [Int]) -> some View {
        HStack(spacing: 16) {
            Group {
                ForEach(indices, id: \.self) { index in
                    podcastCover(index, shadow: shadow)
                }
            }
            .frame(width: size.width * scale, height: size.width * scale)
        }
    }

    @ViewBuilder func footerView() -> some View {
        StoryFooter2024(title: L10n.eoyStoryListenedToNumbers(listenedNumbers.numberOfPodcasts, listenedNumbers.numberOfEpisodes),
                        description: L10n.eoyStoryListenedToNumbersSubtitle)
    }

    @ViewBuilder
    func podcastCover(_ index: Int, shadow: Bool) -> some View {
        let podcast = podcasts[safe: index] ?? podcasts[safe: index % 2 == 0 ? 0 : 1] ?? podcasts[0]
        PodcastImage(uuid: podcast.uuid, size: .grid)
            .clipShape(RoundedRectangle(cornerRadius: 6))
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
            StoryShareableText(L10n.eoyStoryListenedToNumbersShareText(listenedNumbers.numberOfPodcasts, listenedNumbers.numberOfEpisodes), year: .y2024)
        ]
    }
}
