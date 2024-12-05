import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct TopSpotStory2024: ShareableStory {
    let topPodcast: TopPodcast

    private let foregroundColor = Color.black
    private let backgroundColor = Color(hex: "#EDB0F3")

    @State private var rotation: Double = 360

    let identifier: String = "top_1_show"

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            GeometryReader { proxy in
                ZStack {
                    PodcastImage(uuid: topPodcast.podcast.uuid, size: .page, aspectRatio: nil, contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .mask {
                            let maskInset = CGSize(width: proxy.size.height - 550, height: proxy.size.height - 550)
                            InwardSidesRectangle(inwardAngle: .degrees(5))
                                .frame(width: proxy.size.width + maskInset.width, height: proxy.size.width + maskInset.height)
                                .rotationEffect(.degrees(rotation))
                                .animation(.linear(duration: 30).repeatForever(autoreverses: false), value: rotation)
                                .onAppear {
                                    rotation = 0
                                }
                        }
                    Image("playback-sticker-top-spot")
                        .position(x: 18, y: 20, for: CGSize(width: 213, height: 101), in: proxy.frame(in: .local))
                }
            }
            VStack {
                let timeString = topPodcast.totalPlayedTime.storyTimeDescriptionForSharing
                let numberPlayed = topPodcast.numberOfPlayedEpisodes
                let title = topPodcast.podcast.title ?? "unknown"
                StoryFooter2024(title: L10n.playback2024TopSpotTitle, description: L10n.playback2024TopSpotDescription(numberPlayed, timeString, title))
            }
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
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
            StoryShareableText(L10n.eoyStoryTopPodcastShareText("%1$@"), podcast: topPodcast.podcast, year: .y2024)
        ]
    }
}


fileprivate struct InwardSidesRectangle: Shape {
    let inwardAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Calculate the inward distance for each side
        let horizontalInset = rect.height * 0.5 * tan(inwardAngle.radians)
        let verticalInset = rect.width * 0.5 * tan(inwardAngle.radians)

        // Start from top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top edge - goes from corner to middle point and back to other corner
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + horizontalInset))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX - verticalInset, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - horizontalInset))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        // Left edge
        path.addLine(to: CGPoint(x: rect.minX + verticalInset, y: rect.midY))

        path.closeSubpath()

        return path
    }
}
