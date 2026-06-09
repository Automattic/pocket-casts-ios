import SwiftUI

struct ListeningHistoryView: View {

    @State private var model = ListeningHistoryViewModel()
    @Namespace private var rowNamespace

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
            model.load()
        }
    }

    private var episodeList: some View {
        List {
            Section {
                ForEach(model.episodes) { episode in
                    EpisodeRowWithActions(model: episode)
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
        EmptyDataView(title: L10n.tvHistoryEmptyTitle, subtitle: L10n.tvHistoryEmptySubtitle)
    }
}

#Preview {
    ListeningHistoryView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
