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
    let selectedOption: SharingModal.Option

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
            case .clip:
                VStack(spacing: 16) {
                    MediaTrimBar(clipTime: clipTime)
                        .frame(height: 72)
                        .tint(color)
                    Button("Clip", action: {
                        print("Clip: s:\(clipTime.start) e:\(clipTime.end)")
                    }).buttonStyle(RoundedButtonStyle(theme: theme, backgroundColor: color))
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.white)
    }

    var color: Color {
        switch selectedOption {
        case .clip(let episode, _):
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
                ShareImageView(info: selectedOption.imageInfo, style: style)
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
}

#Preview {
    SharingView(destinations: [.copyLinkOption], selectedOption: .podcast(Podcast.previewPodcast()))
        .background(Color.black)
}
