import SwiftUI

struct UpNextView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model = UpNextViewModel()

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                upNextView
            case .empty:
                emptyView
            }
        }
        .task {
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var upNextView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(L10n.tvTabUpNext)
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                }
                upNextListView
                    .frame(maxWidth: 1160)
            }
        }
    }

    var emptyView: some View {
        EmptyDataView(title: L10n.tvUpNextEmptyTitle, subtitle: L10n.tvUpNextEmptySubtitle, actionTitle: L10n.tvUpNextEmptyActionTitle) {
            tabRouter.selectedTab = .home
        }
    }

    @Namespace private var rowNamespace
    var upNextListView: some View {
        LazyVStack(alignment: .leading) {
            ForEach(model.episodes) { episode in
                EpisodeRowWithActions(episode: episode, context: .upNext)
                    .prefersDefaultFocus(episode.id == model.episodes.first?.id, in: rowNamespace)
            }
        }
        .focusScope(rowNamespace)
        .padding(24)
    }

}

#Preview {
    UpNextView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
