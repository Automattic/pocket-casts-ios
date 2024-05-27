import SwiftUI

struct UpNextHistoryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = UpNextHistoryModel()

    var body: some View {
        List(model.historyEntries) { entry in
            Button(action: {
                model.reAddMissingItems(entry: entry.date)
            }, label: {
                Text("\(entry.date.formatted()): \(entry.episodeCount) episodes")
            })
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
