import SwiftUI
import PocketCastsDataModel

struct PodcastDetailView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel
    @Environment(\.requireAccount) private var requireAccount
    @State var model: PodcastDetailViewModel

    @FocusState private var focusedSection: FocusSection?
    @FocusState private var rowFocus: EpisodeRowFocus?
    @State private var isShowingMoreInfo = false

    init(podcast: Podcast) {
        self.model = PodcastDetailViewModel(podcast: podcast)
    }

    init(model: PodcastDetailViewModel) {
        self.model = model
    }

    enum FocusSection: Hashable {
        case episodes
    }

    enum Layout {
        static let podcastImageSize = CGFloat(418)
        static let infoPanelWidth = CGFloat(568)
        static let gutter = CGFloat(24)
        static let rowInsets = EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16)
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                podcastView
            case .failed:
                failedView
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .defaultFocus($focusedSection, .episodes)
        .task {
            Analytics.track(.podcastScreenShown, properties: ["uuid": model.podcastUuid])
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var failedView: some View {
        ContentUnavailableView {
            Text(L10n.tvPodcastErrorTitle)
        } description: {
            Text(L10n.tvPodcastErrorMessage)
        } actions: {
            Button(L10n.ok) {
                dismiss()
            }
        }
    }

    var podcastView: some View {
        HStack(alignment: .top, spacing: Layout.gutter) {
            podcastInfo
                .frame(width: Layout.infoPanelWidth)
            episodeContent
        }
        .blurredCoverBackground(size: Layout.podcastImageSize) {
            PodcastImage(uuid: model.podcastUuid, size: .page)
        }
    }

    var podcastInfo: some View {
        VStack(alignment: .leading, spacing: 40) {
            PodcastImage(uuid: model.podcastUuid, size: .page)
                .frame(width: Layout.podcastImageSize, height: Layout.podcastImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .pcShadowStrong, radius: 40, x: 0, y: 20)
            VStack(alignment: .leading, spacing: 8) {
                Text(model.podcast?.author ?? "")
                    .font(.caption)
                    .foregroundColor(.pcTextSecondary)
                Text(model.podcast?.title ?? "")
                    .font(.title2)
                    .foregroundColor(.pcTextPrimary)
                Text(model.podcast?.podcastDescription ?? "")
                    .font(.caption)
                    .foregroundColor(.pcTextSecondary)
                    .lineLimit(3)
            }
            .accessibilityElement(children: .combine)
            HStack(spacing: 8) {
                Button() {
                    requireAccount {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            if model.isFollowing {
                                model.unsubscribe()
                            } else {
                                model.subscribe()
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: model.isFollowing ? "checkmark" : "plus")
                            .contentTransition(.symbolEffect(.replace))
                        Text(model.isFollowing ? L10n.tvPodcastDetailFollowingTitle : L10n.tvPodcastDetailFollowTitle)
                            .contentTransition(.interpolate)
                    }
                    .font(.caption2)
                }
                Button() {
                    Analytics.track(.podcastScreenToggleSummary, properties: ["is_expanded": true])
                    isShowingMoreInfo = true
                } label: {
                    Text(L10n.tvPodcastDetailMoreInfoTitle)
                        .font(.caption2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .focusSection()
        .sheet(isPresented: $isShowingMoreInfo) {
            if let podcast = model.podcast {
                PodcastMoreInfoView(podcast: podcast)
            } else {
                Text(L10n.loading)
            }
        }
    }

    @State private var lastFocus: String?
    @FocusState private var currentFocus: String?

    private func episodeRow(for episode: EpisodeRowViewModel) -> some View {
        EpisodeRowWithActions(model: episode, showEpisodeNotesImage: Settings.loadEmbeddedImages, focus: $rowFocus, detailsDismissed: {
            currentFocus = lastFocus
        })
        .focused($currentFocus, equals: episode.id)
    }

    private var sortMenu: some View {
        Menu {
            Section(L10n.sortBy) {
                ForEach(PodcastEpisodeSortOrder.allCases, id: \.self) { order in
                    Button {
                        model.setSortOrder(order)
                    } label: {
                        if model.sortOrder == order {
                            Label(order.description, systemImage: "checkmark")
                        } else {
                            Text(order.description)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityLabel(L10n.sortBy)
        }
        .buttonStyle(MoreButtonStyle())
    }

    private var archivedFilterMenu: some View {
        Menu {
            Button {
                model.setShowArchived(false)
            } label: {
                if model.showArchived {
                    Text(L10n.tvPodcastDetailHideArchived)
                } else {
                    Label(L10n.tvPodcastDetailHideArchived, systemImage: "checkmark")
                }
            }
            Button {
                model.setShowArchived(true)
            } label: {
                if model.showArchived {
                    Label(L10n.tvPodcastDetailShowArchived, systemImage: "checkmark")
                } else {
                    Text(L10n.tvPodcastDetailShowArchived)
                }
            }
        } label: {
            ArchivedFilterLabel(showArchived: model.showArchived)
        }
        .accessibilityLabel(L10n.tvPodcastDetailArchivedFilter)
    }

    private struct ArchivedFilterLabel: View {
        let showArchived: Bool

        var body: some View {
            HStack(spacing: 8) {
                Text(showArchived ? L10n.tvPodcastDetailShowArchived : L10n.tvPodcastDetailHideArchived)
                Image(systemName: "chevron.down")
            }
            .font(.caption2)
            .foregroundStyle(Color.pcTextPrimary)
        }
    }

    @Namespace private var episodeListNamespace

    @ViewBuilder
    var episodeContent: some View {
        if model.episodes.isEmpty {
            noEpisodesView
        } else {
            episodeList
        }
    }

    var noEpisodesView: some View {
        ContentUnavailableView(
            L10n.tvPodcastDetailNoEpisodesTitle,
            systemImage: "list.bullet",
            description: Text(L10n.tvPodcastDetailNoEpisodesSubtitle)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var episodeList: some View {
        List {
            if let recommended = model.recommendedEpisode {
                Section {
                    episodeRow(for: recommended)
                        .prefersDefaultFocus(in: episodeListNamespace)
                        .listRowInsets(Layout.rowInsets)
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tvPodcastDetailStartHere)
                            .font(.title3)
                            .foregroundStyle(Color.pcTextPrimary)
                        Text(L10n.tvPodcastDetailStartHereSubtitle)
                            .font(.caption)
                            .foregroundStyle(Color.pcTextSecondary)
                    }
                    .padding(.bottom, 32)
                }
            }
            Section {
                ForEach(model.episodes) { episode in
                    episodeRow(for: episode)
                        .listRowInsets(Layout.rowInsets)
                }
            } header: {
                HStack(alignment: .center, spacing: 8) {
                    Text(L10n.tvPodcastDetailAllEpisodes)
                        .font(.title3)
                        .foregroundStyle(Color.pcTextPrimary)
                    Spacer()
                    archivedFilterMenu
                    sortMenu
                }
                .padding(.top, 40)
                .padding(.bottom, 32)
            }
        }
        .focusScope(episodeListNamespace)
        .padding(.horizontal, 24)
        .contentMargins(.bottom, 24, for: .scrollContent)
        .focused($focusedSection, equals: .episodes)
        .onChange(of: rowFocus) { _, new in
            if let new {
                lastFocus = new.episodeID
            }
        }
        .onAppear {
            currentFocus = lastFocus
        }
    }
}

#Preview {
    let router = MainTabViewModel()
    PodcastDetailView(model: PodcastDetailViewModel(podcast: MockData.makeStubPodcasts().first!))
        .environment(AppCoordinator())
        .environment(router)
}
