import SwiftUI

struct ListeningHistoryView: View {

    @State private var model = ListeningHistoryViewModel()
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
            Analytics.track(.listeningHistoryShown)
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
                Text(L10n.listeningHistory)
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
            }
            .focusScope(rowNamespace)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Text(L10n.tvHistoryEmptyTitle)
        } description: {
            Text(L10n.tvHistoryEmptySubtitle)
        }
    }
}

#Preview {
    ListeningHistoryView()
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
