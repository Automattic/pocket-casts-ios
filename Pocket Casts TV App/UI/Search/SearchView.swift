import SwiftUI

struct SearchView<ViewModel: SearchableViewModel>: View {

    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @Bindable var model: ViewModel
    @State private var searchText = ""

    @State private var path = StackPath()

    var body: some View {
        NavigationStack(path: $path.navigationPath) {
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
                        Text(" \(scope.localizedName) ")
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
                Analytics.track(.searchShown, properties: ["source": "search"])
            }
        }
        .syncNavigationDetail(path: path.navigationPath, tabRouter: tabRouter)
        .environment(path)
    }
}

#Preview {
    SearchView(model: SearchViewModel())
        .environment(MainTabViewModel())
}
