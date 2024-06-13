import SwiftUI
import PocketCastsUtils

struct FolderHistoryEntryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = FolderHistoryModel()
    @Environment(\.dismiss) var dismiss

    @State var showingAlert = false

    let entryDate: Date

    init(entryDate: Date) {
        self.entryDate = entryDate

        if #unavailable(iOS 16.0) {
            UITableView.appearance().backgroundColor = .clear
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button(L10n.restore) {
                    showingAlert = true
                }
                .alert(L10n.restoreFolders, isPresented: $showingAlert, actions: {
                    Button(L10n.restore) {
                        model.restore()
                        dismiss()
                    }
                    Button(L10n.cancel, role: .cancel) { }
                }, message: {
                    Text(L10n.restoreFoldersMessage)
                })
                Spacer()
                Text("\(entryDate.formatted())").bold()
                Spacer()
                Button(L10n.cancel) {
                    dismiss()
                }
            }.padding()

            List(model.podcastsAndFolders, id: \.0.uuid) { podcast, folder in
                HStack {
                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading) {
                        Text(L10n.podcastRemovedFromFolder(podcast.title ?? "", folder.name))
                            .foregroundStyle(theme.primaryText02)
                            .font(style: .footnote)
                    }
                }
                .listRowBackground(theme.primaryUi02)
                .listRowSeparatorTint(theme.primaryUi05)
            }
        }
        .modifier(HiddenScrollContentBackground())
        .background(theme.primaryUi04)
        .onAppear { model.loadFoldersHistory(for: entryDate) }
        .navigationTitle("\(entryDate.formatted())")
        .applyDefaultThemeOptions()
    }
}

#Preview {
    UpNextEntryView(entryDate: Date())
}
