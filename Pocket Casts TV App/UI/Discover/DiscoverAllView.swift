import SwiftUI
import PocketCastsServer

struct DiscoverAllView: View {

    @State private var model: DiscoverAllViewModel

    init(model: DiscoverAllViewModel) {
        _model = State(wrappedValue: model)
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView()
            case .ready:
                discoverList
            case .empty:
                ContentUnavailableView {
                    Text(L10n.tvDiscoverFailedToLoadTitle)
                } description: {
                    Text(L10n.tvDiscoverFailedToLoadSubtitle)
                }
            case .failed:
                DiscoverRetryView(style: .fullScreen) { await model.retry() }
            }
        }
        .task {
            await model.load()
        }
    }

    var discoverList: some View {
        ScrollView {
            LazyVStack(spacing: RowSectionLayout.sectionSpacing) {
                ForEach(Array(model.sections.enumerated()), id: \.offset) { _, item in
                    DiscoverRowSection(item: item, source: DiscoverAnalytics.searchSource)
                }
            }
        }
        .navigationDestination(for: DiscoverCategory.self) { discoverCategory in
            DiscoverPodcastsListView(category: discoverCategory, source: DiscoverAnalytics.searchSource)
        }
    }
}

extension DiscoverItem {

    var focusStoreID: String {
        self.uuid ?? self.id ?? self.type ?? ""
    }
}
