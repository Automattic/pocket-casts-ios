import SwiftUI
import PocketCastsServer

struct DiscoverVideoEpisodesRow: View {

    fileprivate enum Layout {
        static let spacing = CGFloat(48)
    }

    @FocusState private var focusedID: String?
    @Namespace private var focusNS
    @Environment(\.resetFocus) var resetFocus

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
                resetFocus(in: focusNS)
            }
        }
    }

    var podcastList: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Layout.spacing, content: {
                ForEach(model.episodes, id: \.uuid) { episode in
                    DiscoverVideoEpisodeCell(episode: episode)
                        .padding(.vertical, Layout.spacing / 2)
                        .setFocus(section: model.type)
                        .focused($focusedID, equals: episode.uuid)
                        .prefersDefaultFocus(model.episodes.first?.uuid == episode.uuid, in: focusNS)
                }
            })
            .focusSection()
            .focusScope(focusNS)
        }
    }
}
