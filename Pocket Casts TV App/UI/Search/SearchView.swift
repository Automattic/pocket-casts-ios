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
                    SearchResultsView(model: model)
                }
            }
            .searchable(text: $searchText, prompt: "Podcasts, shows, authors")
            .searchSuggestions {
                if searchText.isEmpty {
                    ForEach(model.searchHistory, id: \.self) { search in
                        Text(search).searchCompletion(search)
                    }
                } else {
                    ForEach(model.autoCompleteSuggestions, id: \.self) { suggestion in
                        Text(suggestion)
                            .searchCompletion(suggestion)
                    }
                }
            }
            .onSubmit {
                model.saveHistory(searchText)
            }
            .onChange(of: searchText) { _, newValue in
                model.search(query: newValue)
            }
        }
    }
}

#Preview {
    SearchView(model: SearchViewModel())
}
