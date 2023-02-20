import SwiftUI

struct SearchHistoryView: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack {
            HStack {
                Text("Recent searches")
                Spacer()
                Button("Clear all") {}
            }
            List {
                Text("A Search Item")
                Text("A Second Search Item")
                Text("A Third Search Item")
            }
            .listStyle(.plain)
        }
        .applyDefaultThemeOptions()
    }
}

struct SearchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHistoryView()
    }
}
