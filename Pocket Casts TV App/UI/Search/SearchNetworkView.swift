import PocketCastsServer
import SwiftUI

/// The screen a network tapped in search opens: the podcasts the network's list holds.
struct SearchNetworkView: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
        static let descriptionWidth = CGFloat(1200)
    }

    @State private var model: SearchNetworkModel

    init(network: NetworkSearchResult) {
        _model = State(wrappedValue: SearchNetworkModel(network: network))
    }

    private let gridColumns: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.gridSize), spacing: 48)
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                ProgressView()
            case .ready:
                podcastsView
            case .empty:
                ContentUnavailableView {
                    Text(model.network.title)
                } description: {
                    Text(L10n.tvPodcastsEmptySubtitle)
                }
            case .failed:
                DiscoverRetryView(style: .fullScreen) { await model.retry() }
            }
        }
        .task {
            await model.load()
        }
        .toolbar(.hidden, for: .tabBar)
    }

    private var podcastsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                header
                podcastGrid
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.network.title)
                .font(.title2)
                .foregroundStyle(Color.pcTextPrimary)
            if let description = model.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(Color.pcTextSecondary)
                    .frame(maxWidth: Layout.descriptionWidth, alignment: .leading)
            }
        }
    }

    private var podcastGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 48) {
            ForEach(model.podcasts, id: \.uuid) { podcast in
                NavigationLink(value: podcast) {
                    DiscoverPodcastCell(podcastUuid: podcast.uuid ?? "", isSponsored: false)
                }
                .buttonStyle(.card)
                .accessibilityLabel(podcast.title ?? "")
                .simultaneousGesture(TapGesture().onEnded {
                    model.trackPodcastTapped(podcast)
                })
            }
        }
    }
}

@Observable
@MainActor
final class SearchNetworkModel {

    enum State: Equatable {
        case loading
        case ready
        case empty
        case failed
    }

    let network: NetworkSearchResult

    private(set) var state: State = .loading

    private(set) var podcasts: [DiscoverPodcast] = []

    /// The list's own blurb, which is longer than the one search returns.
    private(set) var description: String?

    private let serverHandler: DiscoverServerHandler

    private var listId: String?

    init(network: NetworkSearchResult, serverHandler: DiscoverServerHandler = DiscoverServerHandler.shared) {
        self.network = network
        self.serverHandler = serverHandler
        self.description = network.description
    }

    func load() async {
        guard case .loading = state else { return }

        guard let collection = await serverHandler.discoverPodcastCollection(source: network.source, authenticated: nil) else {
            state = .failed
            return
        }

        podcasts = collection.podcasts ?? []
        description = collection.description ?? network.description
        listId = collection.listId ?? network.uuid
        state = podcasts.isEmpty ? .empty : .ready
    }

    func retry() async {
        state = .loading
        await load()
    }

    func trackPodcastTapped(_ podcast: DiscoverPodcast) {
        guard let podcastUuid = podcast.uuid, let listId else { return }

        DiscoverAnalytics.podcastTapped(listId: listId, podcastUuid: podcastUuid, source: DiscoverAnalytics.searchSource)
    }
}

#Preview {
    SearchNetworkView(network: NetworkSearchResult(
        uuid: "c73d120f-c174-4324-b0a3-18f9b239a59d",
        title: "WNYC",
        description: "New York's flagship public radio station",
        collectionImage: "https://static.pocketcasts.com/share/images/c73d120f-c174-4324-b0a3-18f9b239a59d-author.png",
        podcastCount: 11
    ))
    .environment(AppCoordinator())
    .environment(MainTabViewModel())
}
