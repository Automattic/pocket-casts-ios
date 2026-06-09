import SwiftUI
import PocketCastsServer

struct DiscoverSinglePodcastRow: View {

    @State private var model: DiscoverSectionModel

    private let callback: ((String?)->())?

    init(item: DiscoverItem, callback: ((String?) -> ())? = nil) {
        _model = State(wrappedValue: DiscoverSectionModel(item: item))
        self.callback = callback
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView()
            case .empty:
                EmptyView()
            case .ready:
                podcastList
            }
        }
        .task {
            await model.load()
            await MainActor.run {
                callback?(model.title)
            }
        }
    }

    var podcastList: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48, content: {
                ForEach(model.podcasts, id: \.uuid) { podcast in
                    NavigationLink(value: podcast) {
                        DiscoverSinglePodcastCell(model: podcast, sponsored: model.isSponsored)
                            .containerRelativeFrame( .horizontal, alignment: .leading) { length, axis in
                                if axis == .vertical {
                                    return 368
                                } else {
                                    return length * 0.92
                                }
                            }
                    }
                    .setFocus(section: model.focusStoreID)
                    .buttonStyle(ChromelessButtonStyle())
                }
            })
        }
    }
}
