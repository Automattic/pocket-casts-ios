import SwiftUI
import PocketCastsServer

struct DiscoverFeaturedPodcastsRow: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
    }

    @State private var model: DiscoverSectionModel

    private let callback: ((String?)->())?

    init(type: DiscoverType, source: String, callback: ((String?) -> ())? = nil) {
        _model = State(wrappedValue: DiscoverSectionModel(type: type, source: source))
        self.callback = callback
    }

    init(item: DiscoverItem, source: String, callback: ((String?) -> ())? = nil) {
        _model = State(wrappedValue: DiscoverSectionModel(item: item, source: source))
        self.callback = callback
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView()
            case .empty:
                EmptyView()
            case .failed:
                RowSection(title: model.title, focusSection: model.focusStoreID) {
                    DiscoverRetryView(style: .row) { await model.retry() }
                }
            case .ready:
                RowSection(title: model.title, focusSection: model.focusStoreID) {
                    podcastList
                }
            }
        }
        .task {
            await model.load()
            await MainActor.run {
                callback?(model.title)
                model.trackImpression()
            }
        }
    }

    @FocusState private var focusedID: String?
    @State private var scrollPosition: String?

    var podcastList: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 64, content: {
                ForEach(model.podcasts, id: \.uuid) { podcast in
                    DiscoverFeaturedPodcastCell(podcast: podcast, sponsored: model.sponsored.contains(podcast.uuid ?? ""), listId: model.listId, source: model.source)
                        .setFocus(section: model.focusStoreID)
                        .id(podcast.uuid)
                        .focused($focusedID, equals: podcast.uuid)
                }
            })
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPosition, anchor: .leading)
        .scrollDisabled(true)
        .scrollClipDisabled()
        .onChange(of: focusedID) { _, id in
            withAnimation(.smooth) {
                scrollPosition = id
            }
        }
    }
}
