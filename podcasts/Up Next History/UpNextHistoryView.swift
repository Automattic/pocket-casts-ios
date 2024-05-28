import SwiftUI
import PocketCastsDataModel

struct UpNextHistoryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = UpNextHistoryModel()

    @State var presentingEntry = false
    @State var selectedEntry: UpNextHistoryManager.UpNextHistoryEntry?

    var body: some View {
        List {
            Section {

            } footer: {
                Text(L10n.upNextHistoryExplanation)
            }

            Section {
                ForEach(model.historyEntries) { entry in
                    Button(action: {
                        selectedEntry = entry
                        presentingEntry = true
                    }, label: {
                        Text("\(entry.date.formatted()): \(entry.episodeCount) \((entry.episodeCount > 1 ? L10n.episodes : L10n.episode).lowercased())")
                    })
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            UpNextEntryView(entryDate: entry.date)
        }
        .onAppear {
            model.loadEntries()
        }
        .navigationTitle(L10n.upNextHistory)
        .applyDefaultThemeOptions()
    }
}

#Preview {
    UpNextHistoryView()
}
