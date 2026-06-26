import SwiftUI

struct SearchView<ViewModel: SearchableViewModel>: View {

    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @Bindable var model: ViewModel
    @State private var searchText = ""
    @State private var didTrackShown = false

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                SearchResultsView(model: model)
            }
            .searchable(text: $searchText, prompt: L10n.tvSearchPrompt)
            .searchSuggestions {
                if model.isInSearchMode {
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
        .onChange(of: path) { _, newPath in
            if newPath.isEmpty {
                tabRouter.isShowingDetail = false
            } else {
                tabRouter.isShowingDetail = true
            }
        }
    }
}

#Preview {
    SearchView(model: SearchViewModel())
}
