import SwiftUI
import PocketCastsDataModel

struct Top5Podcasts2024Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let top5Podcasts: [TopPodcast]

    let identifier: String = "top_5_shows"

    private let shapeColor = Color.green

    private let foregroundColor = Color.black
    private let backgroundColor = Color(hex: "#E0EFAD")
    private let shapeImages = ["playback-2024-shape-pentagon",
                               "playback-2024-shape-two-ovals",
                               "playback-2024-shape-wavy-circle"]

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: 0.8, animation: Animation.spring(_:))

    @State private var itemScale: Double = 1 // This will be set in `setInitialAnimationValues`
    @State private var itemOpacity: Double = 1 // This will be set in `setInitialAnimationValues`

    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height <= 700
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    podcastList()
                        .modifier(animationViewModel.animate($itemOpacity, to: 1, after: 0.1))
                        .modifier(animationViewModel.animate($itemScale, to: 1))
                }
                .modify { view in
                    if renderForSharing {
                        view
                    } else {
                        ScrollView(.vertical) {
                            if #available(iOS 16.4, *) {
                                view.scrollIndicators(.never)
                                    .scrollBounceBehavior(.basedOnSize)
                            } else {
                                view
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .disabled(!isSmallScreen) // Disable scrolling on larger where we shouldn't be clipping.
                .frame(height: geometry.size.height * 0.65)
                StoryFooter2024(title: L10n.eoyStoryTopPodcastsTitle, description: nil)
                .padding(.bottom, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .foregroundStyle(foregroundColor)
        .background(
            Rectangle()
                .fill(backgroundColor)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
        .onAppear {
            if animated {
                setInitialAnimationValues()
                animationViewModel.play()
            }
        }
    }

    @ViewBuilder func podcastList() -> some View {
        ForEach(Array(zip(top5Podcasts.indices, top5Podcasts)), id: \.1.podcast.uuid) { index, item in
            listCell(index: index, item: item)
        }
    }

    @ViewBuilder func listCell(index: Int, item: TopPodcast) -> some View {
        HStack {
            let imageSize: Double = 72
            let textAnimationOffset = imageSize/2
            Text("#\(index + 1)")
                .font(.system(size: 22, weight: .semibold))
                .opacity(itemOpacity)
                .offset(x: (1 - itemScale) * textAnimationOffset)

            ZStack {
                Image(shapeImages[index % shapeImages.count])
                    .foregroundStyle(shapeColor)
                PodcastImage(uuid: item.podcast.uuid, size: .grid)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .scaleEffect(itemScale)

            VStack(alignment: .leading) {
                if let author = item.podcast.author {
                    Text(author)
                        .font(.system(size: 15))
                }
                if let title = item.podcast.title {
                    Text(title)
                        .font(.system(size: 18, weight: .medium))
                }
            }
            .opacity(itemOpacity)
            .offset(x: (1 - itemScale) * -textAnimationOffset)
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

    private func setInitialAnimationValues() {
        itemScale = 0
        itemOpacity = 0
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyStoryTopPodcastsShareText("%1$@"), podcasts: top5Podcasts.map { $0.podcast }, year: .y2024)
        ]
    }
}
