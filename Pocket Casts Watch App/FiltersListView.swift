import SwiftUI

struct FiltersListView: View {
    @StateObject var viewModel = FiltersListViewModel()

    var body: some View {
        ItemListContainer(isEmpty: viewModel.filters.isEmpty, noItemsTitle: L10n.watchNoFilters, loading: viewModel.isLoading) {
            List {
                ForEach(viewModel.filters, id: \.uuid) { filter in
                    NavigationLink(destination: FilterEpisodeListView(viewModel: FilterEpisodeListViewModel(filter: filter))) {
                        MenuRow(label: filter.title, icon: filter.iconName ?? "filter_list", count: viewModel.episodeCount(for: filter))
                    }
                }
            }
        }
        .navigationTitle(L10n.filters.prefixSourceUnicode)
        .onAppear {
            viewModel.loadData()
        }
    }
}

#Preview {
    FiltersListView()
}
