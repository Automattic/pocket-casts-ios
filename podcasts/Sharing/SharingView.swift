import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

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
    }

    let destinations: [ShareDestination]

    @State private var shareable: Shareable
    @State private var isExporting: Bool = false

    @ObservedObject var clipTime: ClipTime

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
            image
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
                            shareable.option = .clipShare(episode, clipTime, shareable.style, Progress())
                            isExporting = true
                        }
                    }).buttonStyle(RoundedButtonStyle(theme: theme, backgroundColor: color))
                }
                .padding(.horizontal, 16)
            case .clipShare(_, _, _, let progress):
                if progress.fileURL == nil && progress.fractionCompleted != 1 {
                    ProgressView(progress)
                        .tint(color)
                        .padding()
                } else {
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

    @ViewBuilder var image: some View {
        TabView(selection: $shareable.style) {
            ForEach(ShareImageStyle.allCases, id: \.self) { style in
                ShareImageView(info: shareable.option.imageInfo, style: style, angle: .constant(0))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .tabItem { Text(style.tabString) }
            }
        }
        .tabViewStyle(.page)
    }

    @ViewBuilder var buttons: some View {
        HStack(spacing: 24) {
            ForEach(destinations, id: \.self) { destination in
                if let action = destination.action {
                    button(destination: destination, style: shareable.style, action: action)
                } else {
                    if #available(iOS 16, *) {
                        shareLink(option: shareable.option, destination: destination, style: shareable.style)
                    }
                }
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

    @available(iOS 16.0, *)
    @ViewBuilder func shareLink(option: SharingModal.Option, destination: ShareDestination, style: ShareImageStyle) -> some View {
        ShareLink(items: shareItems(style: style), preview: { _ in
            SharePreview(option.imageInfo.title, image: Image(uiImage: ShareImageView(info: option.imageInfo, style: style, angle: .constant(0)).snapshot()))
        }) {
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
              case let .clipShare(episode, clipTime, shareable.style, progress) = shareable.option
        else {
            return
        }
        defer {
            isExporting = false
        }
        do {
            let url = try await export(info: shareable.option.imageInfo,
                                            style: shareable.style,
                                            episode: episode,
                                            startTime: CMTime(seconds: clipTime.start, preferredTimescale: 600),
                                            duration: CMTime(seconds: clipTime.end - clipTime.start, preferredTimescale: 600),
                                            progress: progress
            )
            progress.fileURL = url
            shareable.option = .clipShare(episode, clipTime, shareable.style, progress)
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

@available(iOS 16.0, *)
extension SharingView.Shareable: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation<Self>(exportedContentType: .m4a) { shareable in
            switch shareable.option {
            case .clipShare(_, _, _, let progress):
                let fileURL = try progress.fileURL.throwOnNil()
                return try Data(contentsOf: fileURL)
            default:
                assertionFailure("This should never run due to exporting conditions below")
                throw Optional<Void>.OptionalNil()
            }
        }.exportingCondition { shareable in
            guard shareable.shareType == .audio,
                  case .clipShare = shareable.option else { return false }
            switch shareable.option {
            case .clipShare:
                return true
            default:
                return false
            }
        }
        .suggestedFileName("clip")
        FileRepresentation<Self>(exportedContentType: .mpeg4Movie) { shareable in
            switch shareable.option {
            case .clipShare(_, _, _, let progress):
                let fileURL = try progress.fileURL.throwOnNil()
                return SentTransferredFile(fileURL)
            default:
                assertionFailure("This should never run due to exporting conditions below")
                throw Optional<Void>.OptionalNil()
            }
        }.exportingCondition { shareable in
            guard shareable.shareType == .video,
                  case .clipShare = shareable.option else { return false }
            switch shareable.option {
            case .clipShare:
                return true
            default:
                return false
            }
        }
        DataRepresentation<Self>(exportedContentType: .png) { shareable in
            return try await ShareImageView(info: shareable.option.imageInfo, style: shareable.style, angle: .constant(0)).snapshot().pngData().throwOnNil()
        }.exportingCondition { shareable in
            guard shareable.shareType == .image else { return false }
            switch shareable.option {
            case .clipShare:
                return false
            default:
                return true
            }
        }
        ProxyRepresentation { shareable in
            try URL(string: shareable.option.shareURL).throwOnNil()
        }
        .exportingCondition { shareable in
            return shareable.shareType == .url
        }
    }
}

#Preview {
    SharingView(destinations: [.copyLinkOption], selectedOption: .podcast(Podcast.previewPodcast()))
        .background(Color.black)
}
