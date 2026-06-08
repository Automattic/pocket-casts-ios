import SwiftUI
import PocketCastsServer

struct DiscoverFeaturedPodcastsRow: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
    }

    @State private var model: DiscoverSectionModel

    private let callback: ((String?)->())?

    init(type: DiscoverType, callback: ((String?) -> ())? = nil) {
        _model = State(wrappedValue: DiscoverSectionModel(type: type))
        self.callback = callback
    }

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

    @FocusState private var focusedID: String?
    @State private var scrollPosition: String?

    var podcastList: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48, content: {
                ForEach(model.podcasts, id: \.uuid) { podcast in
                    DiscoverFeaturedPodcastCell(podcast: podcast, sponsored: model.sponsored.contains(podcast.uuid ?? ""))
                        .setFocus(section: model.item?.uuid ?? model.item?.id)
                        .id(podcast.uuid)
                        .focused($focusedID, equals: podcast.uuid)
                }
            })
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPosition, anchor: .leading)
        .scrollDisabled(true)
        .onChange(of: focusedID) { _, id in
            withAnimation(.default) {
                scrollPosition = id
            }
        }
    }
}
