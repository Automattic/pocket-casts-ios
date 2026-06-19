import SwiftUI
import PocketCastsServer

struct DiscoverPodcastRow: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
    }

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
            case .ready:
                HomeSection(title: model.title, focusSection: model.focusStoreID) {
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
                            FocusedPodcastCover(uuid: uuid, size: Layout.gridSize)
                        }
                        .buttonStyle(.card)
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

/// Bare podcast cover that picks up the focused-card surface depth treatment.
/// Has to live as its own `View` so `@Environment(\.isFocused)` resolves to the
/// `.card` button's focus state rather than the row's.
private struct FocusedPodcastCover: View {
    let uuid: String
    let size: CGFloat

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        PodcastImage(uuid: uuid, size: .page)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .focusedCardDepth(isFocused: isFocused, cornerRadius: 12, style: .surface)
    }
}
