import SwiftUI

struct EpisodesHorizontalList: View {

    let title: String
    let focusSection: String
    let episodes: [EpisodeRowViewModel]
    let episodeContext: EpisodeActionContext

    let onPlay: () -> Void

    enum Layout {
        static var buttonSpacing = CGFloat(24)
        static var buttonWidth = CGFloat(864)
    }

    var body: some View {
        RowSection(title: title, focusSection: focusSection) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: Layout.buttonSpacing) {
                    ForEach(episodes) { episode in
                        episodeButton(model: episode)
                            .frame(width: Layout.buttonWidth)
                            .setFocus(section: focusSection)
                    }
                }
            }
            // Otherwise the focused-card drop shadow gets clipped at the
            // scroll-view boundary instead of pooling below the pill.
            .scrollClipDisabled()
        }
    }

    func episodeButton(model: EpisodeRowViewModel) -> some View {
        Button {
            model.play()
            onPlay()
        } label: {
            EpisodeRow(model: model, isActive: false)
        }
        .buttonStyle(EpisodeRowButtonStyle())
        .episodeContextMenu(model: model, context: episodeContext)
    }
}

#Preview {
    EpisodesHorizontalList(title: "Episode",
                           focusSection: "Episodes",
                           episodes: MockData.makeStubEpisodes().map({EpisodeRowViewModel(episode: $0, podcast: nil, source: .unknown)}),
                           episodeContext: .other(showGoToPodcast: true)) {
        //no-op
    }
    .environment(AppCoordinator())
    .environment(MainTabViewModel())
    .environment(FocusStore())
}
