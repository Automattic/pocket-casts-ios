import SwiftUI

struct SearchViewContainer: View {

    @State private var model = SearchViewModel()

    var body: some View {
        SearchView(model: model)
    }
}
