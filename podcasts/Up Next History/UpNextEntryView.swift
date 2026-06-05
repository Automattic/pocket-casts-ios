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
    }

    var body: some View {
        if LiquidGlass.isEnabled, #available(iOS 26.0, *) {
            liquidGlassBody
        } else {
            legacyBody
        }
    }

    @available(iOS 26.0, *)
    private var liquidGlassBody: some View {
        NavigationStack {
            episodeList
                .listStyle(.plain)
                .navigationTitle("\(entryDate.formatted())")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.restore) {
                            showingAlert = true
                        }
                    }
                }
                .restoreAlert(isPresented: $showingAlert, onRestore: restore)
        }
        .applyDefaultThemeOptions()
    }

    private var legacyBody: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button(L10n.restore) {
                    showingAlert = true
                }
                .restoreAlert(isPresented: $showingAlert, onRestore: restore)
                Spacer()
                Text("\(entryDate.formatted())").bold()
                Spacer()
                Button(L10n.cancel) {
                    dismiss()
                }
            }.padding()

            episodeList
        }
        .navigationTitle("\(entryDate.formatted())")
        .background(theme.primaryUi04)
        .applyDefaultThemeOptions()
    }

    private var episodeList: some View {
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
        .modifier(HiddenScrollContentBackground())
        .onAppear { model.loadEpisodes(for: entryDate) }
    }

    private func restore() {
        model.reAddMissingItems(entry: entryDate)
        dismiss()
    }
}

private extension View {
    func restoreAlert(isPresented: Binding<Bool>, onRestore: @escaping () -> Void) -> some View {
        alert(L10n.restoreUpNext, isPresented: isPresented, actions: {
            Button(L10n.restore, action: onRestore)
            Button(L10n.cancel, role: .cancel) { }
        }, message: {
            Text(L10n.restoreUpNextMessage)
        })
    }
}

#Preview {
    UpNextEntryView(entryDate: Date())
}
