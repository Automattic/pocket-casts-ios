import SwiftUI

struct PlaylistCell: View {
    let playlist: MockPlaylist

    enum Layout {
        static let gridSize = CGFloat(496)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading) {
                Text(playlist.title)
                Text(playlist.manual ? " " : "Smart Playlist")
                Spacer()
                HStack(alignment: .bottom) {
                    Text("\(playlist.episodes.count) episodes")
                    Spacer()
                }
            }
            .padding(.vertical, 24)
            ZStack {
                ForEach(Array(playlist.episodes.prefix(2).enumerated()), id: \.element) { index, episode in
                    Image(episode.image)
                        .resizable()
                        .frame(width: 156, height: 156)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.2), radius: 37.5, x: 0, y: 0)
                        .offset(x: CGFloat(1-index) * 25.0, y: (CGFloat(2-index) * 25.0))
                }
            }

        }
        .padding(.horizontal, 36)
        .frame(height: 210)
        .background(playlist.color)
        .clipped()
    }

}

#Preview {
    PlaylistCell(playlist: MockData.makePlaylists().first!)
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
