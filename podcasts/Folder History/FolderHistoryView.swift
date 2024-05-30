import SwiftUI
import PocketCastsDataModel

struct FolderHistoryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = FolderHistoryModel()

    @State var presentingEntry = false
    @State var selectedEntry: FolderHistoryManager.PodcastFoldersHistoryEntry?

    init() {
        if #unavailable(iOS 16.0) {
            UITableView.appearance().backgroundColor = .clear
        }
    }

    var body: some View {
        List {
            Section {

            } footer: {
                Text(L10n.upNextHistoryExplanation)
                    .foregroundStyle(theme.primaryText02)
            }

            Section {
                ForEach(model.historyEntries) { entry in
                    Button(action: {
                        selectedEntry = entry
                        presentingEntry = true
                    }, label: {
                        Text("\(entry.date.formatted()): \(entry.changesCount) podcasts removed from folders")
                    })
                    .listRowBackground(theme.primaryUi02)
                    .listRowSeparatorTint(theme.primaryUi05)
                }
            }
        }
        .modifier(HiddenScrollContentBackground())
        .background(theme.primaryUi04)
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
