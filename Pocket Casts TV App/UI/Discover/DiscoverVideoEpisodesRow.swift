import SwiftUI
import PocketCastsServer

struct DiscoverVideoEpisodesRow: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
    }

    @State private var model: DiscoverSectionEpisodesModel

    private let callback: ((String?)->())?

    init(type: DiscoverType, callback: ((String?) -> ())? = nil) {
        _model = State(wrappedValue: DiscoverSectionEpisodesModel(type: type))
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
                ForEach(model.episodes, id: \.uuid) { episode in
                    DiscoverVideoEpisodeCell(episode: episode)
                        .padding(.vertical, 24)
                        .setFocus(section: model.type)
                        .id(episode.uuid)
                        .focused($focusedID, equals: episode.uuid)
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
