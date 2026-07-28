import SwiftUI

struct UpNextEpisodeActionView: View {
    @Binding var isCurrentlyPlaying: Bool
    let episodeAction: EpisodeAction

    var body: some View {
        EpisodeActionView(iconName: isCurrentlyPlaying ? episodeAction.secondaryIconName : episodeAction.iconName,
                          title: episodeAction.title)
    }
}

struct UpNextEpisodeActionView_Previews: PreviewProvider {
    static var previews: some View {
        UpNextEpisodeActionView(isCurrentlyPlaying: .constant(true), episodeAction: .playNext)
            .previewDevice(.largeWatch)
    }
}
