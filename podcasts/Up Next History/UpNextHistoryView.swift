import SwiftUI
import PocketCastsDataModel

struct UpNextHistoryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = UpNextHistoryModel()

    @State var presentingEntry = false
    @State var selectedEntry: UpNextHistoryManager.UpNextHistoryEntry?

    var body: some View {
        List(model.historyEntries) { entry in
            Button(action: {
                selectedEntry = entry
                presentingEntry = true
            }, label: {
                Text("\(entry.date.formatted()): \(entry.episodeCount) episodes")
            })
        }
        .sheet(item: $selectedEntry) { entry in
            UpNextEntryView(entryDate: entry.date)
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
