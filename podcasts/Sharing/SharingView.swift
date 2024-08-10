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

    @EnvironmentObject var theme: Theme

    private enum Constants {
        static let descriptionMaxWidth: CGFloat = 200
    }

    let destinations: [ShareDestination]

    @State var selectedOption: SharingModal.Option
    @State private var isExporting: Bool = false
    @State private var selectedMedia: ShareImageStyle

    @ObservedObject var clipTime: ClipTime

    init(destinations: [ShareDestination], selectedOption: SharingModal.Option, selectedMedia: ShareImageStyle = .large) {
        self.destinations = destinations
        self.selectedOption = selectedOption
        self.selectedMedia = selectedMedia

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
            switch selectedOption {
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
                            selectedOption = .clipShare(episode, clipTime, selectedMedia, Progress())
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
            guard isExporting,
                  case let .clipShare(episode, clipTime, shareImageStyle, progress) = selectedOption
            else {
                return
            }
            defer {
                isExporting = false
            }
            do {
                let url = try await exportVideo(info: selectedOption.imageInfo,
                                                style: selectedMedia,
                                                episode: episode,
                                                startTime: CMTime(seconds: clipTime.start, preferredTimescale: 600),
                                                duration: CMTime(seconds: clipTime.end - clipTime.start, preferredTimescale: 600),
                                                progress: progress
                )
                progress.fileURL = url
                selectedOption = .clipShare(episode, clipTime, shareImageStyle, progress)
            } catch let error {
                FileLog.shared.addMessage("Failed Clip Export: \(error)")
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.white)
    }

    var color: Color {
        switch selectedOption {
        case .clip(let episode, _), .clipShare(let episode, _, _, _):
            PlayerColorHelper.backgroundColor(for: episode)?.color ?? PlayerColorHelper.playerBackgroundColor01(for: theme.activeTheme).color
        default:
            PlayerColorHelper.playerBackgroundColor01(for: theme.activeTheme).color
        }
    }

    @ViewBuilder var title: some View {
        VStack {
            Text(selectedOption.shareTitle)
                .font(.headline)
            switch selectedOption {
            case .clip:
                EmptyView() // Don't show the description to give extra space for trim view
            case .clipShare(let episode, let clipTime, _, _):
                Button(action: {
                    withAnimation {
                        selectedOption = .clip(episode, clipTime.playback)
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
        TabView(selection: $selectedMedia) {
            ForEach(ShareImageStyle.allCases, id: \.self) { style in
                ShareImageView(info: selectedOption.imageInfo, style: style, angle: .constant(0))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .tabItem { Text(style.tabString) }
            }
        }
        .tabViewStyle(.page)
    }

    @ViewBuilder var buttons: some View {
        HStack(spacing: 24) {
            ForEach(destinations, id: \.self) { option in
                Button {
                    option.action(selectedOption, selectedMedia)
                } label: {
                    VStack {
                        option.icon
                            .renderingMode(.template)
                            .font(size: 20, style: .body, weight: .bold)
                            .frame(width: 24, height: 24)
                            .padding(15)
                            .background {
                                Circle()
                                    .foregroundStyle(.white.opacity(0.1))
                            }
                        Text(option.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    enum VideoExportError: Error {
        case failedToDownload
    }

    private func exportVideo(info: ShareImageInfo, style: ShareImageStyle, episode: some BaseEpisode, startTime: CMTime, duration: CMTime, progress: Progress) async throws -> URL {
        guard let playerItem = DownloadManager.shared.downloadParallelToStream(of: episode) else {
            throw VideoExportError.failedToDownload
        }
        let size = CGSize(width: style.videoSize.width * 2, height: style.videoSize.height * 2)
        guard #available(iOS 16, *) else {
            throw VideoExportError.failedToDownload
        }
        let video = VideoExporter(view: AnimatedShareImageView(info: info, style: style), duration: CMTimeGetSeconds(duration), size: size, audioPlayerItem: playerItem, audioStartTime: startTime, audioDuration: duration)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("video_export-\(UUID().uuidString)", conformingTo: .mpeg4Movie)
        try await video.exportTo(outputURL: url, fileType: .mp4, progress: progress)
        return url
    }
}

#Preview {
    SharingView(destinations: [.copyLinkOption], selectedOption: .podcast(Podcast.previewPodcast()))
        .background(Color.black)
}
