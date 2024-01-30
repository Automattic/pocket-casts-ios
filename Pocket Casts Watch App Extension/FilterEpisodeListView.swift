import SwiftUI

struct FilterEpisodeListView: View {
    private static let filterUUIDKey = "filterUUID"

    static func context(withFilter filter: Filter) -> [String: Any] {
        [filterUUIDKey: filter.uuid]
    }

    @ObservedObject var viewModel: FilterEpisodeListViewModel
    private let iconSize: CGFloat = 21

    init?(context: Any?) {
        guard let context = context as? [String: Any],
              let uuid = context[Self.filterUUIDKey] as? String,
              let viewModel = FilterEpisodeListViewModel(filterUUID: uuid)
        else {
            return nil
        }

        self.init(viewModel: viewModel)
    }

    init(viewModel: FilterEpisodeListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        headerWithContent {
            ItemListContainer(isEmpty: $viewModel.episodes.isEmpty, loading: viewModel.isLoading) {
                EpisodeListView(title: L10n.settingsFiles.prefixSourceUnicode, showArtwork: true, episodes: $viewModel.episodes, playlist: .filter(uuid: viewModel.filter.uuid))
            }
        }
        .navigationTitle(L10n.filters.prefixSourceUnicode)
        .onAppear {
            viewModel.loadFilterEpisodes()
        }
    }

    var header: some View {
        HStack {
            if let iconName = viewModel.filter.iconName {
                Image(iconName)
                    .frame(width: iconSize, height: iconSize)
            }
            Text(viewModel.filter.title)
                .font(.dynamic(size: 16))
        }
        .foregroundColor(.lightGray)
        .padding(.vertical, 5)
    }

    func headerWithContent<T: View>(@ViewBuilder _ content: () -> T) -> some View {
        Group {
            if viewModel.isLoading || $viewModel.episodes.isEmpty {
                VStack {
                    header
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    content()
                    Spacer()
                }
            } else {
                List {
                    Section(content: {
                        content()
                    }, header: { header.textCase(.none) } )
                }
            }
        }
    }
}

struct FilterEpisodeListView_Previews: PreviewProvider {
    static var testFilter: WatchFilter {
        let filter = WatchFilter()
        filter.title = "New Releases"
        filter.iconName = "filter_headphones"
        return filter
    }

    static var previews: some View {
        ForEach(PreviewDevice.previewDevices) {
            FilterEpisodeListView(viewModel: FilterEpisodeListViewModel(filter: testFilter))
                .previewDevice($0)
        }
    }
}
