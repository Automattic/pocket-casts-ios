import SwiftUI

struct EpisodesHorizontalList: View {

    let title: String
    let focusSection: String
    let episodes: [EpisodeRowViewModel]
    let episodeContext: EpisodeActionContext

    let callback: (()->())?

    var body: some View {
        RowSection(title: title, focusSection: focusSection) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 24) {
                    ForEach(episodes) { episode in
                        episodeButton(model: episode)
                            .frame(width: 864)
                            .setFocus(section: focusSection)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    func episodeButton(model: EpisodeRowViewModel) -> some View {
        Button {
            model.play()
            callback?()
        } label: {
            EpisodeRow(model: model, isActive: false)
        }
        .buttonStyle(EpisodeRowButtonStyle())
        .episodeContextMenu(model: model, context: episodeContext)
    }
}
