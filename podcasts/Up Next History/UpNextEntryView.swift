import SwiftUI
import PocketCastsUtils

struct UpNextEntryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model = UpNextHistoryModel()
    @Environment(\.dismiss) var dismiss

    @State var showingAlert = false

    let entryDate: Date

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button("Restore") {
                    showingAlert = true
                }
                .alert("Restore Up Next?", isPresented: $showingAlert, actions: {
                    Button("Restore") {
                        model.reAddMissingItems(entry: entryDate)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                }, message: {
                    Text("These episodes will be added to the bottom of your current Up Next")
                })
                Spacer()
                Text("\(entryDate.formatted())").bold()
                Spacer()
                Button("Cancel") {
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
            }
        }
        .onAppear { model.loadEpisodes(for: entryDate) }
        .navigationTitle("\(entryDate.formatted())")
        .applyDefaultThemeOptions()
    }
}

#Preview {
    UpNextEntryView(entryDate: Date())
}
