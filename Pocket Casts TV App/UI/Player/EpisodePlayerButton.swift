import SwiftUI

struct EpisodePlayerButton: View {
    let model: EpisodeRowViewModel
    @State private var isPlaying = false

    var body: some View {
        Button {
            isPlaying = true
        } label: {
            EpisodeRow(model: model, isActive: false)
        }
        .buttonStyle(EpisodeRowButtonStyle())
        .fullScreenCover(isPresented: $isPlaying) {
            EpisodePlayerView(episode: model)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    EpisodePlayerButton(model: EpisodeRowViewModel(episode: MockData.makeStubEpisodes().first!, podcast: MockData.makeStubPodcasts().first!))
}
