import SwiftUI
import PocketCastsDataModel

fileprivate enum Layout {
    static let cellSize = CGFloat(250)
}

struct SearchResultsView<ViewModel: SearchableViewModel>: View {

    @Bindable var model: ViewModel

    private let items: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.cellSize), spacing: 48)
    }

    var body: some View {
        switch model.state {
        case .searching:
            ProgressView("Searching...")
        case .empty:
            ContentUnavailableView.search(text: model.searchTerm)
        case .results:
            results
        case .error(let error):
            Text("Search failed: \(error.localizedDescription)")
        case .query:
            Text("Type something...")
        }
    }

    var results: some View {
        ScrollView {
            LazyVGrid(columns: items, spacing: 48, content: {
                ForEach(model.podcastUuids, id: \.self) { podcast in
                    NavigationLink(value: podcast) {
                        PodcastImage(uuid: podcast, size: .page)
                            .frame(width: Layout.cellSize, height: Layout.cellSize)
                    }
                    .buttonStyle(.card)
                }
            })
            .navigationDestination(for: String.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: podcast))
            }
        }
    }
}
