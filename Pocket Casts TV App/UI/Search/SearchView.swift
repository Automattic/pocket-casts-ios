import SwiftUI

struct SearchView<ViewModel: SearchableViewModel>: View {

    @Bindable var viewModel: ViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                if searchText.isEmpty {
                    EmptyDataView(title: "No results found", subtitle: "Search for something more specific", actionTitle: nil, action: nil)
                } else {
                    switch viewModel.state {
                    case .searching:
                        ProgressView("Searching...")
                    case .empty:
                        ContentUnavailableView.search(text: searchText)
                    case .results:
                        SearchPodcastsResultsView(podcasts: viewModel.results)
                    case .error(let error):
                        Text("Search failed: \(error.localizedDescription)")
                    case .query:
                        Text("Type something...")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Podcasts, shows, authors")
            .searchScopes($viewModel.scope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .searchSuggestions {
                if searchText.isEmpty {
                    Section("Recent") {
                        ForEach(viewModel.searchHistory, id: \.self) { search in
                            Label(search, systemImage: "clock")
                                .searchCompletion(search)
                        }
                    }
                } else {
                    // Live suggestions based on query
                    ForEach(viewModel.autoCompleteSuggestions, id: \.self) { suggestion in
                        Text(suggestion)
                            .searchCompletion(suggestion)
                    }
                }
            }
            .onSubmit(of: .search) {
                viewModel.search(query: searchText)
            }
            .onChange(of: searchText) { _, newValue in
                viewModel.autoComplete(query: newValue)
            }
        }
    }
}

#Preview {
    SearchView(viewModel: SearchViewModel())
}
