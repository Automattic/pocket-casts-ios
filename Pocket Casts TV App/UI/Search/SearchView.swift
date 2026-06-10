import SwiftUI

struct SearchView<ViewModel: SearchableViewModel>: View {

    @Bindable var model: ViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                SearchResultsView(model: model)
            }
            .searchable(text: $searchText, prompt: L10n.tvSearchPrompt)
            .if(model.isInSearchMode) { content in
                content.searchSuggestions {
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
                .searchScopes($model.scope, scopes: {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.localizedName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .tag(scope)
                    }
                })
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
