import SwiftUI
import PocketCastsServer

struct DiscoverEpisodesRow: View {

    fileprivate enum Layout {
        static let spacing = CGFloat(56)
    }

    @FocusState private var focusedID: String?
    @Namespace private var focusNS
    @Environment(\.resetFocus) var resetFocus

    @State private var model: DiscoverSectionEpisodesModel

    private let callback: ((String?)->())?

    init(type: DiscoverType, source: String, callback: ((String?) -> ())? = nil) {
        _model = State(wrappedValue: DiscoverSectionEpisodesModel(type: type, source: source))
        self.callback = callback
    }

    init(item: DiscoverItem, source: String, callback: ((String?) -> ())? = nil) {
        _model = State(wrappedValue: DiscoverSectionEpisodesModel(item: item, source: source))
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
                    mainContent
                }
            }
        }
        .task {
            await model.load()
            await MainActor.run {
                callback?(model.title)
                model.trackImpression()
                resetFocus(in: focusNS)
            }
        }
    }

    var mainContent: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Layout.spacing, content: {
                ForEach(model.episodes, id: \.uuid) { episode in
                    DiscoverEpisodeCell(episode: episode, listId: model.listId, source: model.source)
                }
            })
            .focusSection()
            .focusScope(focusNS)
        }
        // Otherwise the focused-card drop shadow gets clipped at the
        // scroll-view boundary instead of pooling below the pill.
        .scrollClipDisabled()
    }
}
