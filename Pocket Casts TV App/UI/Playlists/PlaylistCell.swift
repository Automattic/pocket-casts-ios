import SwiftUI
import PocketCastsDataModel

struct PlaylistCell: View {
    @State var playlist: PlaylistDetailsViewModel

    init(playlist: EpisodeFilter) {
        self.playlist = PlaylistDetailsViewModel(playlist: playlist)
    }

    @Environment(\.isFocused) var isFocused: Bool

    enum Layout {
        static let imageSize = CGFloat(156)
        static let rotationEffect = CGFloat(15)
        static let cardHeight = CGFloat(258)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading) {
                Text(playlist.playlistName)
                    .font(.headline)
                    .foregroundColor(isFocused ? Color.textPrimaryActive : Color.textPrimary)
                if playlist.isManual {
                    Text(L10n.smartPlaylist)
                        .font(.caption)
                        .foregroundColor(isFocused ? Color.textSecondaryActive : Color.textSecondary)
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text(playlist.state == .loading ? "" : playlist.episodeCountText)
                        .font(.caption)
                        .foregroundColor(isFocused ? Color.textSecondaryActive : Color.textSecondary)
                    Spacer()
                }
            }
            .padding(.vertical, 24)
            ZStack {
                if playlist.state == .ready {
                    ForEach(Array(playlist.coverPodcastsUuids.prefix(2).enumerated()), id: \.element) { index, podcastUuid in
                        PodcastImageViewWrapper(podcastUUID: podcastUuid, size: .page)
                            .frame(width: Layout.imageSize, height: Layout.imageSize)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: .black.opacity(0.2), radius: 37.5, x: 0, y: 0)
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
        .background(isFocused ? Color.backgroundActive : playlist.playlistColor)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
        .clipped()
        .task {
            playlist.load()
        }
    }

}

#Preview {
    PlaylistCell(playlist: MockData.makeStubPlaylists().first!)
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
