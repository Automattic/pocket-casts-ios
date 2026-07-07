import SwiftUI

struct StarredEpisodesView: View {

    @State private var model = StarredEpisodesViewModel()
    @Namespace private var rowNamespace
    @FocusState private var rowFocus: EpisodeRowFocus?

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                ProgressView()
            case .ready:
                episodeList
            case .empty:
                emptyView
            }
        }
        .task {
            Analytics.track(.starredShown)
            model.load()
        }
        .remotePlayPause()
    }

    private var episodeList: some View {
        List {
            Section {
                ForEach(model.episodes) { episode in
                    EpisodeRowWithActions(model: episode, focus: $rowFocus)
                        .frame(width: 1160)
                        .prefersDefaultFocus(episode.id == model.episodes.first?.id, in: rowNamespace)
                }
            } header: {
                Text(L10n.tvProfileMenuStarredEpisodes)
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
            }
            .focusScope(rowNamespace)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Text(L10n.tvStarredEmptyTitle)
        } description: {
            Text(L10n.tvStarredEmptySubtitle)
        }
    }
}

#Preview {
    StarredEpisodesView()
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
