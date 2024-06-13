import SwiftUI
import PocketCastsUtils

struct UpNextEntryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = UpNextHistoryModel()
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
                .alert(L10n.restoreUpNext, isPresented: $showingAlert, actions: {
                    Button(L10n.restore) {
                        model.reAddMissingItems(entry: entryDate)
                        dismiss()
                    }
                    Button(L10n.cancel, role: .cancel) { }
                }, message: {
                    Text(L10n.restoreUpNextMessage)
                })
                Spacer()
                Text("\(entryDate.formatted())").bold()
                Spacer()
                Button(L10n.cancel) {
                    dismiss()
                }
            }.padding()

            List(model.episodes, id: \.uuid) { episode in
                HStack {
                    EpisodeImage(episode: episode)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading) {
                        Text("\(DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase)")
                            .foregroundStyle(theme.primaryText02)
                            .font(style: .footnote)
                        Text("\(episode.title ?? "")")
                            .lineLimit(1)
                            .font(style: .body)
                        Text(episode.displayableInfo(includeSize: false))
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
        .onAppear { model.loadEpisodes(for: entryDate) }
        .navigationTitle("\(entryDate.formatted())")
        .applyDefaultThemeOptions()
    }
}

#Preview {
    UpNextEntryView(entryDate: Date())
}
