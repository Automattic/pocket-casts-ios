import SwiftUI
import PocketCastsUtils

struct UpNextView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter
    @Environment(\.requireAccount) private var requireAccount

    @State private var model = UpNextViewModel()
    @State private var showNowPlayingPlayer: Bool = false

    @Namespace private var rowNamespace

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

    var upNextView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                headerRow
                ForEach(queuedEpisodes) { episode in
                    EpisodeRowWithActions(model: episode, context: .upNext)
                        .frame(width: 1160)
                        .prefersDefaultFocus(episode.id == queuedEpisodes.first?.id, in: rowNamespace)
                }
            }
            .focusScope(rowNamespace)
            .fullScreenCover(isPresented: $showNowPlayingPlayer) {
                NowPlayingView()
                    .ignoresSafeArea()
            }
        }
    }

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.tvTabUpNext)
                .font(.title2)
                .foregroundStyle(Color.pcTextPrimary)
            if !queuedEpisodes.isEmpty {
                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)
            }
        }
        .frame(width: 1160, alignment: .leading)
    }

    /// The Up Next queue minus the currently playing episode at index 0, which
    /// the player surfaces elsewhere.
    private var queuedEpisodes: [EpisodeRowViewModel] {
        Array(model.episodes.dropFirst())
    }

    private var summaryText: String {
        let count = queuedEpisodes.count
        let episodeText = count == 1
            ? L10n.podcastEpisodeCountSingular
            : L10n.podcastEpisodeCountPluralFormat("\(count)")
        let totalSeconds = queuedEpisodes.reduce(0.0) { sum, episode in
            sum + max(0, episode.duration - episode.playedUpTo)
        }
        let timeText = L10n.podcastTimeLeft(
            TimeFormatter.shared.multipleUnitFormattedShortTime(time: totalSeconds)
        )
        return "\(episodeText) - \(timeText)"
    }

    var emptyView: some View {
        EmptyDataView(title: L10n.tvUpNextEmptyTitle, subtitle: L10n.tvUpNextEmptySubtitle, actionTitle: L10n.tvUpNextEmptyActionTitle) {
            requireAccount { tabRouter.selectedTab = .home }
        }
    }
}

#Preview {
    UpNextView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
