import SwiftUI

struct EpisodeListView: View {
    let title: String
    let showArtwork: Bool
    @Binding var episodes: [EpisodeRowViewModel]

    var body: some View {
        ForEach(episodes) { episodeViewModel in
            NavigationLink(destination: EpisodeView(viewModel: EpisodeDetailsViewModel(episode: episodeViewModel.episode), listTitle: title)) {
                EpisodeRow(viewModel: episodeViewModel, showArtwork: showArtwork)
                    .padding(-4)
            }
        }
    }
}

struct EpisodeListView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeListView(title: "Test", showArtwork: true, episodes: .constant([]))
    }
}
