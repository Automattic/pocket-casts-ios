import SwiftUI
import PocketCastsServer

struct DiscoverPodcastRow: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
    }

    @State private var model: DiscoverSectionModel

    private let callback: ((String?)->())?

    init(type: DiscoverType, callback: ((String?) -> ())? = nil) {
        _model = State(wrappedValue: DiscoverSectionModel(type: type))
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
                    if let uuid = podcast.uuid {
                        NavigationLink(value: podcast) {
                            PodcastImage(uuid: uuid, size: .page)
                                .frame(width: Layout.gridSize, height: Layout.gridSize)
                        }
                        .buttonStyle(.card)
                        .padding(.vertical, 24)
                        .setFocus(section: model.type)
                    }
                }
            })
        }
        .scrollClipDisabled()
    }
}
