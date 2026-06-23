import SwiftUI
import PocketCastsUtils

struct UpNextView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @State private var model: UpNextViewModel

    @Namespace private var rowNamespace
    @FocusState private var rowFocus: EpisodeRowFocus?

    init(model: UpNextViewModel) {
        _model = State(wrappedValue: model)
    }

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
                    EpisodeRowWithActions(model: episode, context: .upNext, focus: $rowFocus)
                        .frame(width: 1160)
                        .prefersDefaultFocus(episode.id == queuedEpisodes.first?.id, in: rowNamespace)
                }
            }
            .focusScope(rowNamespace)
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
            : L10n.podcastEpisodeCountPluralFormat(count.localized())
        let totalSeconds = queuedEpisodes.reduce(0.0) { sum, episode in
            sum + max(0, episode.duration - episode.playedUpTo)
        }
        let timeText = L10n.podcastTimeLeft(
            TimeFormatter.shared.multipleUnitFormattedShortTime(time: totalSeconds)
        )
        return "\(episodeText) - \(timeText)"
    }

    var emptyView: some View {
        ContentUnavailableView {
            Text(L10n.tvUpNextEmptyTitle)
        } description: {
            Text(L10n.tvUpNextEmptySubtitle)
        } actions: {
            Button(L10n.tvUpNextEmptyActionTitle) {
                tabRouter.selectedTab = .home
            }
        }
    }
}

#Preview {
    UpNextView(model: UpNextViewModel())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
