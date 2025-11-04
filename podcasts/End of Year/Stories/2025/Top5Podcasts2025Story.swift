import SwiftUI
import PocketCastsDataModel
import Lottie

struct Top5Podcasts2025Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let top5Podcasts: [TopPodcast]

    let identifier: String = "top_5_shows"

    private let shapeColor = Color.green

    private let foregroundColor = Color.black
    private let backgroundColor = Color(hex: "#96BCD1")

    @State private var itemScale: Double = 0.8

    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height <= 700
            VStack(alignment: .leading) {
                headerView
                Spacer()
                    .frame(height: 30)
                VStack(alignment: .leading, spacing: 0) {
                    podcastList()
                        .animation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.9), value: itemScale)
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
                .disabled(!isSmallScreen) // Disable scrolling on larger where we shouldn't be clipping.
                .frame(height: geometry.size.height * 0.65)
                .padding(.bottom, 2)
                Spacer()
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
                itemScale = 1.0
            }
        }
    }

    @ViewBuilder var headerView: some View {
        StoryHeader2025(title: "Your other go-to's", description: "More favorites, more play, more you")
    }

    @ViewBuilder func podcastList() -> some View {
        ForEach(Array(zip(top5Podcasts.indices, top5Podcasts)), id: \.1.podcast.uuid) { index, item in
            PodcastCellView(index: index, item: item, itemScale: itemScale)
                .frame(height: 100)
                .padding(.bottom, index == 0 ? 21 : 14)
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
            StoryShareableText(L10n.eoyStoryTopPodcastsShareText("%1$@"), podcasts: top5Podcasts.map { $0.podcast }, year: .y2025)
        ]
    }
}

fileprivate struct PodcastCellView: View {
    let index: Int
    let item: TopPodcast
    let itemScale: Double

    private var animationName: String {
        index%2 == 0 ? "2025_top_5_podcasts_a" : "2025_top_5_podcasts_b"
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                LottieView(animation: .named(animationName))
                    .animationDidFinish({ completed in
                    })
                    .configure({ animationView in
                        animationView.contentMode = .scaleToFill
                    })
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                    .frame(width: 75, height: 100)
                    .offset(x: -10)
                    .ignoresSafeArea()
                Spacer()
            }
            .opacity(0.4)
            HStack(spacing: 0) {
                let imageSize: Double = index == 0 ? 100 : 77
                Text("#\(index + 1)")
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.horizontal, 16.0)
                PodcastImage(uuid: item.podcast.uuid, size: .grid)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 0) {
                    if let author = item.podcast.author {
                        Text(author)
                            .font(.system(size: 15))
                    }
                    if let title = item.podcast.title {
                        Text(title)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                Spacer()
            }
        }
        .background {
            Color.yellow
        }
        .scaleEffect(x: itemScale, y: itemScale, anchor: .leading)
    }
}
