import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

class ClipTime: ObservableObject {
    @Published var start: TimeInterval
    @Published var end: TimeInterval
    @Published var playback: TimeInterval

    private let originalStart: TimeInterval
    private let originalEnd: TimeInterval

    var startChanged: Bool {
        return start != originalStart
    }

    var endChanged: Bool {
        return end != originalEnd
    }

    init(start: TimeInterval, end: TimeInterval, playback: TimeInterval? = nil) {
        self.start = start
        self.end = end
        self.playback = start
        self.originalStart = start
        self.originalEnd = end
    }
}

struct SharingView: View {

    struct Shareable {
        var option: SharingModal.Option
        var style: ShareImageStyle
        var shareType: UTType? = nil
    }

    private enum Constants {
        static let descriptionMaxWidth: CGFloat = 200
        static let tabViewPadding: CGFloat = 80 // A value which represents extra padding for UIPageControl of the TabView
    }

    let destinations: [ShareDestination]
    let source: AnalyticsSource

    @State private var shareable: Shareable
    @State private var isExporting: Bool = false

    @ObservedObject var clipTime: ClipTime

    private let clipUUID = UUID().uuidString

    init(destinations: [ShareDestination], selectedOption: SharingModal.Option, selectedStyle: ShareImageStyle = .large, source: AnalyticsSource) {
        self.destinations = destinations
        self.shareable = Shareable(option: selectedOption, style: selectedStyle)

        switch selectedOption {
        case .clip(let episode, let time):
            let clipDuration: TimeInterval = 60
            var startTime = time
            var endTime = time + clipDuration
            if endTime > episode.duration {
                startTime = episode.duration - clipDuration
                endTime = episode.duration
            }
            self.clipTime = ClipTime(start: startTime, end: endTime, playback: time)
        default:
            self.clipTime = ClipTime(start: 0, end: 0)
        }

        self.source = source
    }

    var body: some View {
        VStack {
            title
            tabView
            SharingFooterView(clipTime: clipTime, option: $shareable.option, isExporting: $isExporting, destinations: destinations, style: shareable.style, clipUUID: clipUUID, source: source)
        }
        .onAppear {
            var properties = [:]
            let type: String

            switch shareable.option {
            case .clip(let episode, _):
                properties["episode_uuid"] = episode.uuid
                type = "clip"
            case .clipShare(let episode, _, _):
                properties["episode_uuid"] = episode.uuid
                type = "clip"
            case .episode(let episode):
                properties["episode_uuid"] = episode.uuid
                type = "episode"
            case .podcast(let podcast):
                properties["podcast_uuid"] = podcast.uuid
                type = "podcast"
            case .currentPosition(let episode, _):
                properties["episode_uuid"] = episode.uuid
                type = "episode_timestamp"
            }
            properties["clip_uuid"] = clipUUID
            properties["type"] = type

            Analytics.track(.shareScreenShown, source: source, properties: properties)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.white)
    }

    @ViewBuilder var title: some View {
        VStack {
            Text(shareable.option.shareTitle(style: shareable.style))
                .font(.headline)
            switch shareable.option {
            case .clipShare(let episode, let clipTime, _):
                Button(action: {
                    withAnimation {
                        shareable.option = .clip(episode, clipTime.playback)
                    }
                }) {
                    Text(L10n.editClip)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                }
                .padding(.top, 14)
            default:
                EmptyView()
            }
            Text(shareable.style.shareDescription(option: shareable.option) ?? "‏")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: Constants.descriptionMaxWidth)
        }
    }

    @ViewBuilder var tabView: some View {
        GeometryReader { proxy in
            TabView(selection: $shareable.style) {
                switch shareable.option {
                case .clipShare(_, _, let style):
                    image(style: style, containerHeight: proxy.size.height)
                case .clip:
                    ForEach(ShareImageStyle.allCases, id: \.self) { style in
                        image(style: style, containerHeight: proxy.size.height)
                    }
                default:
                    let styles = ShareImageStyle.allCases.filter { $0 != .audio }
                    ForEach(styles, id: \.self) { style in
                        image(style: style, containerHeight: proxy.size.height)
                    }
                }
            }
            .tabViewStyle(.page)
        }
    }

    @ViewBuilder func image(style: ShareImageStyle, containerHeight: CGFloat) -> some View {
        ShareImageView(info: shareable.option.imageInfo, style: style, angle: .constant(0))
            .frame(width: style.previewSize.width, height: style.previewSize.height)
            .fixedSize()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .tabItem { Text(style.tabString) }
            .id(style)
            .scaleEffect((containerHeight - Constants.tabViewPadding) / ShareImageStyle.large.previewSize.height)
	}

    private func shareItems(style: ShareImageStyle) -> [Shareable] {
        var media = shareable
        media.shareType = style == .audio ? .audio : .video
        var image = shareable
        image.shareType = .image

        return [media, (style != .audio ? image : nil)].compactMap { $0 }
    }
}

#Preview {
    SharingView(destinations: [.copyLink], selectedOption: .podcast(Podcast.previewPodcast()), source: .player)
        .background(Color.black)
}
