import SwiftUI
import PocketCastsUtils

struct SharingFooterView: View {
    @ObservedObject var clipTime: ClipTime
    @Binding var option: SharingModal.Option
    @Binding var isExporting: Bool
    @State var progress: Float?

    let destinations: [ShareDestination]
    let style: ShareImageStyle
    let clipUUID: String
    let source: AnalyticsSource

    @State var shareTask: Task<Void, Error>?

    @EnvironmentObject var theme: Theme

    var body: some View {
        switch option {
        case .episode, .podcast, .currentPosition:
            buttons
        case .clip(let episode, _):
            VStack(spacing: 12) {
                MediaTrimBar(clipTime: clipTime, episode: episode, clipUUID: clipUUID, analyticsSource: source)
                    .frame(height: 72)
                    .tint(color)
                HStack {
                    Text(L10n.clipStartLabel(TimeFormatter.shared.playTimeFormat(time: clipTime.start)))
                    Spacer()
                    Text(L10n.clipDurationLabel(TimeFormatter.shared.playTimeFormat(time: clipTime.end - clipTime.start)))
                }
                .foregroundStyle(.white.opacity(0.5))
                .font(.caption.weight(.semibold))
                Button(L10n.next, action: {
                    withAnimation {
                        option = .clipShare(episode, clipTime, style)
                    }
                }).buttonStyle(RoundedButtonStyle(theme: theme, backgroundColor: color))
            }
            .padding(.horizontal, 16)
            .onAppear {
                shareTask?.cancel()
                progress = nil
                isExporting = false
            }
        case .clipShare:
            if let progress {
                ProgressView(value: progress) {
                    Text(L10n.clipLoadingLabel)
                        .font(.headline)
                        .padding(8)
                }
                .tint(color)
                .padding()
            } else {
                buttons
            }
        }
    }

    @ViewBuilder var buttons: some View {
        HStack(spacing: 24) {
            ForEach(destinations, id: \.self) { destination in
                button(destination: destination, style: style, clipUUID: clipUUID, source: source)
            }
        }
    }

    @ViewBuilder func button(destination: ShareDestination, style: ShareImageStyle, clipUUID: String, source: AnalyticsSource) -> some View {
        Button {
            isExporting = true
            shareTask = Task.detached { @MainActor in
                do {
                    try await destination.share(option, style: style, clipTime: clipTime, clipUUID: clipUUID, progress: $progress, source: source)
                } catch let error {
                    if Task.isCancelled { return }
                    await MainActor.run {
                        Toast.show("Failed clip export: \(error.localizedDescription)")
                    }
                }
            }
        } label: {
            view(for: destination)
        }
    }

    var color: Color {
        switch option {
        case .clip(let episode, _), .clipShare(let episode, _, _):
            PlayerColorHelper.backgroundColor(for: episode)?.color ?? PlayerColorHelper.playerBackgroundColor01(for: theme.activeTheme).color
        default:
            PlayerColorHelper.playerBackgroundColor01(for: theme.activeTheme).color
        }
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
}
