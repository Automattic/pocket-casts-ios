import SwiftUI
import PocketCastsUtils

struct SharingFooterView: View {
    @ObservedObject var clipTime: ClipTime
    @Binding var option: SharingModal.Option
    @Binding var isExporting: Bool
    @ObservedObject var clipResult: ClipResult

    let destinations: [ShareDestination]
    let style: ShareImageStyle

    @EnvironmentObject var theme: Theme

    var body: some View {
        switch option {
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
                        option = .clipShare(episode, clipTime, style, clipResult)
                        isExporting = true
                    }
                }).buttonStyle(RoundedButtonStyle(theme: theme, backgroundColor: color))
            }
            .padding(.horizontal, 16)
        case .clipShare:
            if clipResult.progress != 1 {
                ProgressView(value: clipResult.progress) {
                    Text(L10n.clipLoadingLabel)
                        .font(.headline)
                        .padding(8)
                }
                .tint(color)
                .padding()
            }
            else {
                buttons
            }
        }
    }

    @ViewBuilder var buttons: some View {
        HStack(spacing: 24) {
            ForEach(destinations, id: \.self) { destination in
                button(destination: destination, style: style, action: destination.action)
            }
        }
    }

    @ViewBuilder func button(destination: ShareDestination, style: ShareImageStyle, action: @escaping ((SharingModal.Option, ShareImageStyle) -> Void)) -> some View {
        Button {
            action(option, style)
        } label: {
            view(for: destination)
        }
    }

    var color: Color {
        switch option {
        case .clip(let episode, _), .clipShare(let episode, _, _, _):
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
