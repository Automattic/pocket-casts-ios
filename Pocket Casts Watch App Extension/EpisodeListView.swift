import SwiftUI

struct EpisodeListView: View {
    let title: String
    let showArtwork: Bool
    @Binding var episodes: [EpisodeRowViewModel]
    let playlist: AutoplayHelper.Playlist?

    var body: some View {
        ForEach(episodes) { episodeViewModel in
            NavigationLink(destination: EpisodeView(viewModel: EpisodeDetailsViewModel(episode: episodeViewModel.episode, playlist: playlist), listTitle: title)) {
                EpisodeRow(viewModel: episodeViewModel, showArtwork: showArtwork)
            }
        }
    }
}

struct EpisodeListView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeListView(title: "Test", showArtwork: true, episodes: .constant([]), playlist: nil)
    }
}
