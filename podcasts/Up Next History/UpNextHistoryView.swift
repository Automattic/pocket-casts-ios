import SwiftUI

struct UpNextHistoryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = UpNextHistoryModel()

    @State var presentingEntry = false

    var body: some View {
        List(model.historyEntries) { entry in
            Button(action: {
                presentingEntry = true
            }, label: {
                Text("\(entry.date.formatted()): \(entry.episodeCount) episodes")
            })
        }
        .sheet(isPresented: $presentingEntry) { UpNextEntryView() }
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
