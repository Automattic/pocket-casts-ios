import SwiftUI

struct EpisodePlayerButton: View {
    let model: EpisodeRowViewModel
    @State private var isPlaying = false

    var body: some View {
        Button {
            isPlaying = true
            model.play()
        } label: {
            EpisodeRow(model: model, isActive: false)
        }
        .buttonStyle(EpisodeRowButtonStyle())
        .episodeContextMenu(model: model, context: .other(showGoToPodcast: true))
        .fullScreenCover(isPresented: $isPlaying) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    EpisodePlayerButton(model: EpisodeRowViewModel(episode: MockData.makeStubEpisodes().first!, podcast: MockData.makeStubPodcasts().first!, source: .unknown))
}
