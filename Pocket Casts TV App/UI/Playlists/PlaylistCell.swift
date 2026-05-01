import SwiftUI

struct PlaylistCell: View {
    let playlist: MockPlaylist

    @Environment(\.isFocused) var isFocused: Bool

    enum Layout {
        static let imageSize = CGFloat(156)
        static let rotationEffect = CGFloat(15)
        static let cardHeight = CGFloat(258)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading) {
                Text(playlist.title)
                    .font(.headline)
                    .foregroundColor(isFocused ? Color.textPrimaryActive : Color.textPrimary)
                if playlist.manual {
                    Text(L10n.smartPlaylist)
                        .font(.caption)
                        .foregroundColor(isFocused ? Color.textSecondaryActive : Color.textSecondary)
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text(L10n.playlistEpisodesCount(playlist.episodes.count))
                        .font(.caption)
                        .foregroundColor(isFocused ? Color.textSecondaryActive : Color.textSecondary)
                    Spacer()
                }
            }
            .padding(.vertical, 24)
            ZStack {
                ForEach(Array(playlist.episodes.prefix(2).enumerated()), id: \.element) { index, episode in
                    Image(episode.image)
                        .resizable()
                        .frame(width: Layout.imageSize, height: Layout.imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.2), radius: 37.5, x: 0, y: 0)
                        .rotationEffect(Angle(degrees: isFocused ? (index == 0 ? Layout.rotationEffect : -Layout.rotationEffect) : 0))
                        .offset(x: CGFloat(1-index) * 25.0, y: 50 + (CGFloat(2-index) * 25.0))
                }
            }
            .padding(.horizontal, 36)

        }
        .padding(.horizontal, 36)
        .frame(height: Layout.cardHeight)
        .background(isFocused ? Color.backgroundActive : playlist.color)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
        .clipped()
    }

}

#Preview {
    PlaylistCell(playlist: MockData.makePlaylists().first!)
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
