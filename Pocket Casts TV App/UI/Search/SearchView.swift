import SwiftUI

struct SearchView<ViewModel: SearchableViewModel>: View {

    @Bindable var model: ViewModel
    @State private var searchText = ""
    @State private var didTrackShown = false

    var body: some View {
        NavigationStack {
            VStack {
                SearchResultsView(model: model)
            }
            .searchable(text: $searchText, prompt: L10n.tvSearchPrompt)
            .searchSuggestions {
                if model.isInSearchMode {
                    ForEach(model.autoCompleteSuggestions, id: \.self) { suggestion in
                        Button {
                            Analytics.track(.searchPredictiveTermTapped, properties: ["term": suggestion, "source": "search"])
                        } label: {
                            Text(suggestion)
                                .searchCompletion(suggestion)
                        }
                    }
                } else {
                    ForEach(model.searchHistory, id: \.self) { search in
                        Button {
                            Analytics.track(.searchHistoryItemTapped, properties: ["type": "search_term", "source": "search"])
                        } label: {
                            Text(search).searchCompletion(search)
                        }
                    }
                }
            }
            .searchScopes($model.scope) {
                if model.isInSearchMode {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.localizedName)
                            .tag(scope)
                    }
                }
            }
            .onSubmit {
                model.saveHistory(searchText)
            }
            .onChange(of: searchText) { _, newValue in
                model.search(query: newValue)
            }
            .onChange(of: model.scope) { _, newValue in
                Analytics.track(.searchFilterTapped, properties: ["source": "search", "filter": newValue.analyticsDescription])
            }
            .onAppear {
                guard !didTrackShown else { return }
                didTrackShown = true
                Analytics.track(.searchShown, properties: ["source": "search"])
            }
        }
    }
}

#Preview {
    SearchView(model: SearchViewModel())
}
