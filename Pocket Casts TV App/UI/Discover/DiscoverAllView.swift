import SwiftUI
import PocketCastsServer

struct DiscoverAllView: View {

    @State private var model: DiscoverAllViewModel

    private let source: String

    init(model: DiscoverAllViewModel, source: String) {
        _model = State(wrappedValue: model)
        self.source = source
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
                    if model.type == .signedIn || model.type == .signedOut {
                        Text(L10n.tvHomeFailedToLoadTitle)
                    } else {
                        Text(L10n.tvDiscoverFailedToLoadTitle)
                    }
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
            VStack(alignment: .leading, spacing: RowSectionLayout.sectionSpacing) {
                ForEach(Array(model.sections.enumerated()), id: \.offset) { _, item in
                    DiscoverRowSection(item: item, source: source)
                }
            }
        }
    }
}

extension DiscoverItem {

    var focusStoreID: String {
        self.uuid ?? self.id ?? self.type ?? ""
    }
}
