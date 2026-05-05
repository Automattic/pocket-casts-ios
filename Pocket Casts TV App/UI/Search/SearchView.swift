import SwiftUI

struct SearchView<ViewModel: SearchableViewModel>: View {

    @Bindable var model: ViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                if searchText.isEmpty {
                    EmptyDataView(title: "No results found", subtitle: "Search for something more specific", actionTitle: nil, action: nil)
                } else {
                    switch model.state {
                    case .searching:
                        ProgressView("Searching...")
                    case .empty:
                        ContentUnavailableView.search(text: searchText)
                    case .results:
                        SearchPodcastsResultsView(podcasts: model.results)
                    case .error(let error):
                        Text("Search failed: \(error.localizedDescription)")
                    case .query:
                        Text("Type something...")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Podcasts, shows, authors")
            .searchSuggestions {
                if searchText.isEmpty {
                    Section("Recent") {
                        ForEach(model.searchHistory, id: \.self) { search in
                            Label(search, systemImage: "clock")
                                .searchCompletion(search)
                        }
                    }
                } else {
                    // Live suggestions based on query
                    ForEach(model.autoCompleteSuggestions, id: \.self) { suggestion in
                        Text(suggestion)
                            .searchCompletion(suggestion)
                    }
                }
            }
            .onSubmit(of: .search) {
                model.search(query: searchText)
            }
            .onChange(of: searchText) { _, newValue in
                model.autoComplete(query: newValue)
            }
        }
    }
}

#Preview {
    SearchView(model: SearchViewModel())
}
