import SwiftUI
import PocketCastsDataModel

struct PlaylistCell: View {

    var playlist: PlaylistItem
    @State var model: PlaylistDetailsViewModel

    init(playlist: PlaylistItem) {
        self.playlist = playlist
        self.model = PlaylistDetailsViewModel(playlist: playlist)
    }

    @Environment(\.isFocused) var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    enum Layout {
        static let imageSize = CGFloat(156)
        static let rotationEffect = CGFloat(15)
        static let cardHeight = CGFloat(258)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading) {
                Text(model.playlistName)
                    .font(.headline)
                    .foregroundColor(isFocused ? Color.pcTextPrimaryActive : Color.pcTextPrimary)
                if !model.isManual {
                    Text(L10n.smartPlaylist)
                        .font(.caption)
                        .foregroundColor(isFocused ? Color.pcTextSecondaryActive : Color.pcTextSecondary)
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text(model.state == .loading ? "" : model.episodeCountText)
                        .font(.caption)
                        .foregroundColor(isFocused ? Color.pcTextSecondaryActive : Color.pcTextSecondary)
                    Spacer()
                }
            }
            .accessibilityElement(children: .combine)
            // In light mode, use variable for light more over artwork (except for focus state)
            .environment(\.colorScheme, colorScheme == .light ? (isFocused ? .light : .dark) : colorScheme)

            .padding(.vertical, 24)
            ZStack {
                if model.state == .ready {
                    ForEach(Array(model.coverPodcastsUuids.prefix(2).reversed().enumerated()), id: \.element) { index, podcastUuid in
                        PodcastImage(uuid: podcastUuid, size: .page)
                            .frame(width: Layout.imageSize, height: Layout.imageSize)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: .pcShadowLight, radius: 37.5, x: 0, y: 0)
                            .rotationEffect(Angle(degrees: isFocused ? (index == 0 ? Layout.rotationEffect : -Layout.rotationEffect) : 0))
                            .scaleEffect(isFocused ? 1.25 : 1.0)
                            .offset(
                                x: CGFloat(1 - index) * 25.0 - 24 + (index == 0 && !isFocused ? 8 : 0),
                                y: 50 + CGFloat(2 - index) * 25.0 + (index == 0 && !isFocused ? 8 : 0) - (index == 1 ? 8 : 0)
                            )
                    }
                }
            }
            .padding(.horizontal, 36)
        }
        .padding(.horizontal, 36)
        .frame(height: Layout.cardHeight)
        .background(isFocused ? Color.pcBackgroundActive : model.playlistColor)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .focusedCardDepth(isFocused: isFocused, cornerRadius: 16, style: .content)
        .task {
            model.load()
        }
        .onChange(of: playlist) {
            model.playlist = playlist
            model.load()
        }
    }
}

#Preview {
    PlaylistCell(playlist: PlaylistItem(playlist: MockData.makeStubPlaylists().first!))
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
