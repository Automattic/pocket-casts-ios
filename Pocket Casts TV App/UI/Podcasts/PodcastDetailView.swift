import SwiftUI
import PocketCastsDataModel

struct PodcastDetailView: View {

    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter
    @State var model: PodcastDetailViewModel

    @FocusState private var focusedSection: FocusSection?
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
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                podcastView
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .defaultFocus($focusedSection, .episodes)
        .onAppear { tabRouter.isShowingDetail = true }
        .onDisappear { tabRouter.isShowingDetail = false }
        .task {
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var podcastView: some View {
        HStack(alignment: .top, spacing: Layout.gutter) {
            podcastInfo
                .frame(width: Layout.infoPanelWidth)
            episodeContent
        }
        .blurredCoverBackground(size: Layout.podcastImageSize) {
            PodcastImageViewWrapper(podcastUUID: model.podcast.uuid, size: .page)
        }
    }

    var podcastInfo: some View {
        VStack(alignment: .leading, spacing: 40) {
            PodcastImageViewWrapper(podcastUUID: model.podcast.uuid, size: .page)
                .frame(width: Layout.podcastImageSize, height: Layout.podcastImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.6), radius: 40, x: 0, y: 20)
            VStack(alignment: .leading, spacing: 8) {
                Text(model.podcast.author ?? "")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(model.podcast.title ?? "")
                    .font(.title2)
                    .foregroundColor(.textPrimary)
                Text(model.podcast.podcastDescription ?? "")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            HStack(spacing: 8) {
                Button() {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        model.follow()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: model.podcast.subscribed != 0 ? "checkmark" : "plus")
                            .contentTransition(.symbolEffect(.replace))
                        Text(model.isFollowing ? L10n.tvPodcastDetailFollowingTitle : L10n.tvPodcastDetailFollowTitle)
                            .contentTransition(.interpolate)
                    }
                    .font(.caption2)
                }
                Button() {
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
            PodcastMoreInfoView(podcast: model.podcast)
        }
    }

    private func episodeRow(for episode: EpisodeRowViewModel) -> some View {
        EpisodeRowWithActions(model: episode)
    }

    @Namespace private var episodeListNamespace

    var episodeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                if let recommended = model.recommendedEpisode {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tvPodcastDetailStartHere)
                                .font(.title3)
                                .foregroundStyle(Color.textPrimary)
                            Text(L10n.tvPodcastDetailStartHereSubtitle)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        episodeRow(for: recommended)
                        .prefersDefaultFocus(in: episodeListNamespace)
                    }
                }

                LazyVStack(alignment: .leading, spacing: 16) {
                    Text(L10n.tvPodcastDetailAllEpisodes)
                        .font(.title3)
                        .foregroundStyle(Color.textPrimary)
                    LazyVStack {
                        ForEach(model.episodes) { episode in
                            episodeRow(for: episode)
                        }
                    }
                }
            }
            .focusScope(episodeListNamespace)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .focused($focusedSection, equals: .episodes)
    }
}

#Preview {
    let router = MainTabRouter()
    PodcastDetailView(model: PodcastDetailViewModel(podcast: MockData.makeStubPodcasts().first!))
        .environment(AppCoordinator())
        .environment(router)
}
