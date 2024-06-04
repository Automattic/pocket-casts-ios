import SwiftUI
import PocketCastsDataModel

struct UpNextHistoryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = UpNextHistoryModel()

    @State var presentingEntry = false
    @State var selectedEntry: UpNextHistoryManager.UpNextHistoryEntry?

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
                        Text("\(entry.date.formatted()): \(entry.episodeCount) \((entry.episodeCount > 1 ? L10n.episodes : L10n.episode).lowercased())")
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

struct HiddenScrollContentBackground: ViewModifier {
    public func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
        } else {
            content
        }
    }


}

#Preview {
    UpNextHistoryView()
}
