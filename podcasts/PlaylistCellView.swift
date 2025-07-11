import SwiftUI
import PocketCastsDataModel

class PlaylistCellViewModel: ObservableObject {
    let playlist: EpisodeFilter

    init(playlist: EpisodeFilter) {
        self.playlist = playlist
    }
}

struct PlaylistCellView: View {
    let viewModel: PlaylistCellViewModel

    var body: some View {
        HStack {
            Rectangle()
                .frame(width: 56, height: 56)
                .foregroundColor(.red)
                .cornerRadius(4)
                .clipped()
            Spacer()
        }
        .background(.clear)
    }
}

#Preview {
    PlaylistCellView(
        viewModel: PlaylistCellViewModel(
            playlist: EpisodeFilter()
        )
    )
        .frame(width: 350, height: 81)
        .background(.white)
}
