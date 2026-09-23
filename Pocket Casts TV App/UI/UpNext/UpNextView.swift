import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

struct UpNextView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @State private var model: UpNextViewModel
    @State private var path = StackPath()

    @Namespace private var rowNamespace
    @FocusState private var rowFocus: EpisodeRowFocus?

    @State private var lastFocus: String?
    @FocusState private var currentFocus: String?

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
        .focusScope(rowNamespace)
        .task {
            Analytics.track(.upNextShown, properties: ["source": "tab_bar"])
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var upNextView: some View {
        NavigationStack(path: $path.navigationPath) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    headerRow
                    ForEach(model.episodes) { episode in
                        EpisodeRowWithActions(model: episode, context: .upNext, focus: $rowFocus, customPlayDisplayAction: {
                            tabRouter.showFullScreenPlayer = true
                        }, detailsDismissed: {
                            currentFocus = lastFocus
                        })
                        .frame(width: 1160)
                        .focused($currentFocus, equals: episode.id)
                    }
                }
            }
            .focusSection()
            .onChange(of: rowFocus) { _, new in
                if let new {
                    lastFocus = new.episodeID
                }
            }
            .onAppear {
                currentFocus = lastFocus
            }
            .navigationDestination(for: Podcast.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: podcast.uuid))
            }
            .syncNavigationDetail(path: path.navigationPath, tabRouter: tabRouter)
        }.environment(path)
    }

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.tvTabUpNext)
                .font(.title2)
                .foregroundStyle(Color.pcTextPrimary)
            if !model.episodes.isEmpty {
                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)
            }
        }
        .frame(width: 1160, alignment: .leading)
    }

    private var summaryText: String {
        let count = model.episodes.count
        let episodeText = count == 1
            ? L10n.podcastEpisodeCountSingular
            : L10n.podcastEpisodeCountPluralFormat(count.localized())
        let totalSeconds = model.episodes.reduce(0.0) { sum, episode in
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
                Analytics.track(.upNextDiscoverButtonTapped)
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
