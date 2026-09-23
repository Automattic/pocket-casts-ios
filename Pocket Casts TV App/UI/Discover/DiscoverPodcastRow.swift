import SwiftUI
import PocketCastsServer

struct DiscoverPodcastRow: View {

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
        ZStack {
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

    var podcastList: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48, content: {
                ForEach(model.podcasts, id: \.uuid) { podcast in
                    if let uuid = podcast.uuid {
                        NavigationLink(value: podcast) {
                            PodcastCoverCard(uuid: uuid)
                        }
                        .buttonStyle(.card)
                        .accessibilityLabel(podcast.title ?? "")
                        .padding(.vertical, 24)
                        .setFocus(section: model.focusStoreID)
                        .simultaneousGesture(TapGesture().onEnded {
                            model.trackPodcastTapped(podcast)
                        })
                    }
                }
            })
        }
        .scrollClipDisabled()
    }
}
