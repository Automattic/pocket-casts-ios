import SwiftUI
import PocketCastsServer

struct DiscoverEpisodesRow: View {

    fileprivate enum Layout {
        static let spacing = CGFloat(56)
        static let cellWidth = CGFloat(864)
    }

    @State private var model: DiscoverSectionEpisodesModel

    init(item: DiscoverItem, source: String) {
        _model = State(wrappedValue: DiscoverSectionEpisodesModel(item: item, source: source))
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
                model.trackImpression()
            }
        }
    }

    var mainContent: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Layout.spacing, content: {
                ForEach(model.episodes, id: \.uuid) { episode in
                    DiscoverEpisodeCell(episode: episode, listId: model.listId, source: model.source)
                        .frame(width: Layout.cellWidth)
                        .setFocus(section: model.focusStoreID)
                }
            })
            .focusSection()
        }
        .scrollClipDisabled()
    }
}
