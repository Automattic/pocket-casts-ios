import SwiftUI

struct UpNextView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter
    @Environment(\.requireAccount) private var requireAccount

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
            Analytics.track(.upNextShown, properties: ["source": "tab_bar"])
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    @State private var showNowPlayingPlayer: Bool = false

    var upNextView: some View {
        List {
            Section {
                if let currentPlaying = model.episodes.first {
                    NowPlayingRow(model: currentPlaying) {
                        showNowPlayingPlayer = true
                    }
                        .frame(width: 1242, alignment: .leading)
                }
            }
            Section {
                ForEach(model.episodes.dropFirst()) { episode in
                    EpisodeRowWithActions(model: episode, context: .upNext)
                        .frame(width: 1160)
                        .prefersDefaultFocus(episode.id == model.episodes.first?.id, in: rowNamespace)
                }
            } header: {
                Text(L10n.tvTabUpNext)
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
            }
            .focusScope(rowNamespace)
        }
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }

    var emptyView: some View {
        EmptyDataView(title: L10n.tvUpNextEmptyTitle, subtitle: L10n.tvUpNextEmptySubtitle, actionTitle: L10n.tvUpNextEmptyActionTitle) {
            requireAccount { tabRouter.selectedTab = .home }
        }
    }

    @Namespace private var rowNamespace
}

#Preview {
    UpNextView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
