import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

class ClipResult: ObservableObject {
    @MainActor @Published var progress: Float = 0
    @Published var exportURL: URL?
    @Published var croppedURL: URL?
}

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
    @StateObject var clipResult = ClipResult()

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
            SharingFooterView(clipTime: clipTime, option: $shareable.option, isExporting: $isExporting, clipResult: clipResult, destinations: destinations, style: shareable.style, clipUUID: clipUUID, source: source)
        }
        .task(id: isExporting, {
            await exportIfNeeded()
        })
        .onAppear {
            var properties = [:]
            let type: String

            switch shareable.option {
            case .clip(let episode, _):
                properties["episode_uuid"] = episode.uuid
                type = "clip"
            case .clipShare(let episode, _, _, _):
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
            case .clipShare(let episode, let clipTime, _, _):
                Button(action: {
                    isExporting = false
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
                case .clipShare(_, _, let style, _):
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

    private func logShareAction(option: SharingModal.Option, style: ShareImageStyle) {
        var properties: Dictionary<String, Any> = [:]

        switch option {
        case .clip(let episode, _):
            properties["episode_uuid"] = episode.uuid
        case .clipShare(let episode, let clipTime, _, _):
            properties["episode_uuid"] = episode.uuid
            properties["start"] = Int(clipTime.start)
            properties["end"] = Int(clipTime.end)
            properties["start_modified"] = clipTime.startChanged
            properties["end_modified"] = clipTime.endChanged
        case .episode(let episode):
            properties["episode_uuid"] = episode.uuid
        case .podcast(let podcast):
            properties["podcast_uuid"] = podcast.uuid
        case .currentPosition(let episode, _):
            properties["episode_uuid"] = episode.uuid
        }
        properties["clip_uuid"] = clipUUID

        switch style {
        case .large:
            properties["card_type"] = "vertical"
        case .medium:
            properties["card_type"] = "square"
        case .small:
            properties["card_type"] = "horizontal"
        case .audio:
            properties["card_type"] = "audio"
        }

        let shareType: String
        switch (style, option) {
        case (.audio, _):
            shareType = "audio"
        case (_, .clip), (_, .clipShare):
            shareType = "video"
        default:
            shareType = "link"
        }
        properties["type"] = shareType

        Analytics.track(.shareScreenClipShared, source: source, properties: properties)
    }

    private func shareItems(style: ShareImageStyle) -> [Shareable] {
        var media = shareable
        media.shareType = style == .audio ? .audio : .video
        var image = shareable
        image.shareType = .image

        return [media, (style != .audio ? image : nil)].compactMap { $0 }
    }

    enum VideoExportError: Error {
        case failedToDownload
    }

    private func exportIfNeeded() async {
        guard isExporting,
              case let .clipShare(episode, clipTime, shareable.style, _) = shareable.option
        else {
            return
        }
        defer {
            isExporting = false
        }
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // Delay by half a second to let the UI update
            clipResult.progress = Float.leastNormalMagnitude
            let progress = Progress()
            let observation = progress.observe(\.completedUnitCount) { progress, change in
                Task.detached { @MainActor in
                    clipResult.progress = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                }
            }

            let (fullURL, croppedURL) = try await export(info: shareable.option.imageInfo,
                                            style: shareable.style,
                                            episode: episode,
                                            startTime: CMTime(seconds: clipTime.start, preferredTimescale: 600),
                                            duration: CMTime(seconds: clipTime.end - clipTime.start, preferredTimescale: 600),
                                            progress: progress
            )

            clipResult.exportURL = fullURL
            clipResult.croppedURL = croppedURL

            shareable.option = .clipShare(episode, clipTime, shareable.style, clipResult)

            progress.completedUnitCount = progress.totalUnitCount
        } catch let error {
            FileLog.shared.addMessage("Failed Clip Export: \(error)")
        }
    }

    private func export(info: ShareImageInfo, style: ShareImageStyle, episode: some BaseEpisode, startTime: CMTime, duration: CMTime, progress: Progress) async throws -> (URL, URL?) {
        guard let playerItem = DownloadManager.shared.downloadParallelToStream(of: episode) else {
            throw VideoExportError.failedToDownload
        }

        switch style {
        case .audio:
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("audio_export-\(UUID().uuidString)", conformingTo: .m4a)
            try await AudioClipExporter.exportAudioClip(from: playerItem.asset, startTime: startTime, duration: duration, to: url, progress: progress)
            return (url, nil)
        default:
            let size = CGSize(width: style.videoSize.width * 2, height: style.videoSize.height * 2)
            guard #available(iOS 16, *) else { // iOS 15 support will be added in a separate PR just to keep the line count down
                throw VideoExportError.failedToDownload
            }
            let parameters = VideoExporter.Parameters(duration: CMTimeGetSeconds(duration), size: size, episodeAsset: playerItem.asset, audioStartTime: startTime, audioDuration: duration, fileType: .mp4)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("video_export-\(UUID().uuidString)", conformingTo: .mpeg4Movie)
            try await VideoExporter.export(view: AnimatedShareImageView(info: info, style: style), with: parameters, to: url, progress: progress)

            let fittedSize = CGSize(width: shareable.style.videoSize.width * 2, height: shareable.style.videoSize.height * 2).fitting(aspectRatio: shareable.style.previewSize)
            let croppedURL = try await AVAsset(url: url).crop(to: fittedSize)

            return (url, croppedURL)
        }
    }
}

#Preview {
    SharingView(destinations: [.copyLinkOption], selectedOption: .podcast(Podcast.previewPodcast()), source: .player)
        .background(Color.black)
}
