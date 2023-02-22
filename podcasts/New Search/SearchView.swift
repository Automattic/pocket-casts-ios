import SwiftUI

class SearchVisibilityModel: ObservableObject {
    @Published var isSearching = false
}

struct SearchView: View {
    @ObservedObject var displaySearch: SearchVisibilityModel

    var body: some View {
        if displaySearch.isSearching {
            Text("Search results")
        } else {
            SearchHistoryView()
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(displaySearch: SearchVisibilityModel())
    }
}
