import SwiftUI
import PocketCastsServer

struct DiscoverHomeView: View {

    @State private var model: DiscoverHomeViewModel

    init(model: DiscoverHomeViewModel) {
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
        LazyVStack(spacing: RowSectionLayout.sectionSpacing) {
            ForEach(Array(model.sections.enumerated()), id: \.offset) { _, item in
                DiscoverRowSection(item: item, source: DiscoverAnalytics.homeSource)
            }
        }
    }
}
