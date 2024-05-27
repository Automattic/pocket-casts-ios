import SwiftUI

struct UpNextHistoryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = UpNextHistoryModel()

    var body: some View {
        List(model.historyEntries, id: \.self) { entry in
            Text("\(entry)")
        }
        .onAppear {
            model.loadEntries()
        }
        .navigationTitle("Up Next History")
            .applyDefaultThemeOptions()
    }
}

#Preview {
    UpNextHistoryView()
}
