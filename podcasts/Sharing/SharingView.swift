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

    init(start: TimeInterval, end: TimeInterval) {
        self.start = start
        self.end = end
        self.playback = start
    }
}

struct SharingView: View {

    struct Shareable {
        var option: SharingModal.Option
        var style: ShareImageStyle
        var shareType: UTType? = nil
    }

    @EnvironmentObject var theme: Theme

    private enum Constants {
        static let descriptionMaxWidth: CGFloat = 200
        static let tabViewPadding: CGFloat = 80 // A value which represents extra padding for UIPageControl of the TabView
    }

    let destinations: [ShareDestination]

    @State private var shareable: Shareable
    @State private var isExporting: Bool = false

    @ObservedObject var clipTime: ClipTime
    @StateObject var clipResult = ClipResult()

    init(destinations: [ShareDestination], selectedOption: SharingModal.Option, selectedStyle: ShareImageStyle = .large) {
        self.destinations = destinations
        self.shareable = Shareable(option: selectedOption, style: selectedStyle)

        switch selectedOption {
        case .clip(_, let time):
            self.clipTime = ClipTime(start: time, end: time + 60)
        default:
            self.clipTime = ClipTime(start: 0, end: 0)
        }
    }

    var body: some View {
        VStack {
            title
            tabView
            switch shareable.option {
            case .episode, .podcast, .currentPosition:
                buttons
            case .clip(let episode, _):
                VStack(spacing: 12) {
                    MediaTrimBar(clipTime: clipTime, episode: episode)
                        .frame(height: 72)
                        .tint(color)
                    HStack {
                        Text(L10n.clipStartLabel(TimeFormatter.shared.playTimeFormat(time: clipTime.start)))
                        Spacer()
                        Text(L10n.clipDurationLabel(TimeFormatter.shared.playTimeFormat(time: clipTime.end - clipTime.start)))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .font(.caption.weight(.semibold))
                    Button(L10n.clip, action: {
                        withAnimation {
                            shareable.option = .clipShare(episode, clipTime, shareable.style, clipResult)
                            isExporting = true
                        }
                    }).buttonStyle(RoundedButtonStyle(theme: theme, backgroundColor: color))
                }
                .padding(.horizontal, 16)
            case .clipShare:
                if clipResult.progress != 1 {
                    ProgressView(value: clipResult.progress) {
                        Text("Creating Clip...")
                    }
                    .tint(color)
                    .padding()
                }
                else {
                    buttons
                }
            }
        }
        .task(id: isExporting, {
            await exportIfNeeded()
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.white)
    }

    var color: Color {
        switch shareable.option {
        case .clip(let episode, _), .clipShare(let episode, _, _, _):
            PlayerColorHelper.backgroundColor(for: episode)?.color ?? PlayerColorHelper.playerBackgroundColor01(for: theme.activeTheme).color
        default:
            PlayerColorHelper.playerBackgroundColor01(for: theme.activeTheme).color
        }
    }

    @ViewBuilder var title: some View {
        VStack {
            Text(shareable.option.shareTitle)
                .font(.headline)
            switch shareable.option {
            case .clip:
                EmptyView() // Don't show the description to give extra space for trim view
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
                Text(L10n.shareDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: Constants.descriptionMaxWidth)
            }
        }
    }

    @ViewBuilder var tabView: some View {
        GeometryReader { proxy in
            TabView(selection: $shareable.style) {
                switch shareable.option {
                case .clipShare(_, _, let style, _):
                    image(style: style, containerHeight: proxy.size.height)
                default:
                    ForEach(ShareImageStyle.allCases, id: \.self) { style in
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

    @ViewBuilder var buttons: some View {
        HStack(spacing: 24) {
            ForEach(destinations, id: \.self) { destination in
                button(destination: destination, style: shareable.style, action: destination.action)
            }
        }
    }

    @ViewBuilder func button(destination: ShareDestination, style: ShareImageStyle, action: @escaping ((SharingModal.Option, ShareImageStyle) -> Void)) -> some View {
        Button {
            action(shareable.option, shareable.style)
        } label: {
            view(for: destination)
        }
    }

    private func shareItems(style: ShareImageStyle) -> [Shareable] {
        var media = shareable
        media.shareType = style == .audio ? .audio : .video
        var image = shareable
        image.shareType = .image

        return [media, (style != .audio ? image : nil)].compactMap { $0 }
    }

    @ViewBuilder func view(for destination: ShareDestination) -> some View {
        VStack {
            destination.icon
                .renderingMode(.template)
                .font(size: 20, style: .body, weight: .bold)
                .frame(width: 24, height: 24)
                .padding(15)
                .background {
                    Circle()
                        .foregroundStyle(.white.opacity(0.1))
                }
            Text(destination.name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
            let progress = Progress()
            let observation = progress.observe(\.completedUnitCount) { progress, change in
                Task.detached { @MainActor in
                    clipResult.progress = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                }
            }

            let url = try await export(info: shareable.option.imageInfo,
                                            style: shareable.style,
                                            episode: episode,
                                            startTime: CMTime(seconds: clipTime.start, preferredTimescale: 600),
                                            duration: CMTime(seconds: clipTime.end - clipTime.start, preferredTimescale: 600),
                                            progress: progress
            )

            //TODO: Do this in parallel to speed up?
            let fittedSize = CGSize(width: shareable.style.videoSize.width * 2, height: shareable.style.videoSize.height * 2).fitting(aspectRatio: shareable.style.previewSize)
            let croppedURL = try await AVAsset(url: url).crop(to: fittedSize)

            clipResult.exportURL = url
            clipResult.croppedURL = croppedURL

            shareable.option = .clipShare(episode, clipTime, shareable.style, clipResult)

            progress.completedUnitCount = progress.totalUnitCount
        } catch let error {
            FileLog.shared.addMessage("Failed Clip Export: \(error)")
        }
    }

    private func export(info: ShareImageInfo, style: ShareImageStyle, episode: some BaseEpisode, startTime: CMTime, duration: CMTime, progress: Progress) async throws -> URL {
        guard let playerItem = DownloadManager.shared.downloadParallelToStream(of: episode) else {
            throw VideoExportError.failedToDownload
        }

        switch style {
        case .audio:
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("audio_export-\(UUID().uuidString)", conformingTo: .m4a)
            try await AudioClipExporter.exportAudioClip(from: playerItem.asset, startTime: startTime, duration: duration, to: url, progress: progress)
            return url
        default:
            let size = CGSize(width: style.videoSize.width * 2, height: style.videoSize.height * 2)
            guard #available(iOS 16, *) else { // iOS 15 support will be added in a separate PR just to keep the line count down
                throw VideoExportError.failedToDownload
            }
            let parameters = VideoExporter.Parameters(duration: CMTimeGetSeconds(duration), size: size, episodeAsset: playerItem.asset, audioStartTime: startTime, audioDuration: duration, fileType: .mp4)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("video_export-\(UUID().uuidString)", conformingTo: .mpeg4Movie)
            try await VideoExporter.export(view: AnimatedShareImageView(info: info, style: style), with: parameters, to: url, progress: progress)
            return url
        }
    }
}

#Preview {
    SharingView(destinations: [.copyLinkOption], selectedOption: .podcast(Podcast.previewPodcast()))
        .background(Color.black)
}
