import PocketCastsServer
import SwiftUI

struct ColorPreviewFolderView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var model: FolderModel

    var dismissAction: (String?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text(L10n.color.localizedUppercase)
                    .textStyle(SecondaryText())
                    .font(.subheadline)
                    .padding(.bottom, -8)
                ThemedDivider()
                ColorSelectRow(model: model)
                ThemedDivider()
                Text(L10n.folderColorDetail)
                    .font(.footnote)
                    .textStyle(SecondaryText())
                    .padding(.top, -8)
            }
            Group {
                Text(L10n.preview.localizedUppercase)
                    .textStyle(SecondaryText())
                    .font(.subheadline)
                    .padding(.bottom, -8)
                    .padding(.top, 10)
                ThemedDivider()
                HStack {
                    FolderPreviewWrapper(model: model, showName: Settings.libraryType != .list)
                        .frame(width: previewTileSize(), height: previewTileSize())
                    if Settings.libraryType == .list {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(model.name)
                                .textStyle(PrimaryText())
                                .font(.subheadline)
                            Text(L10n.podcastCount(model.selectedPodcastUuids.count))
                                .textStyle(SecondaryText())
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                }
                ThemedDivider()
            }
            Spacer()
            Button {
                let folderUuid = model.createFolder()
                Analytics.track(.folderSaved, properties: ["number_of_podcasts": model.selectedPodcastUuids.count, "color": UIColor(model.color).hexString()])
                dismissAction(folderUuid)
            } label: {
                Text(L10n.folderSaveFolder)
                    .textStyle(RoundedButton())
            }
        }
        .padding()
        .navigationTitle(L10n.folderChooseColor)
        .onAppear {
            Analytics.track(.folderCreateColorShown, properties: ["number_of_podcasts": model.selectedPodcastUuids.count])
        }
        .applyDefaultThemeOptions()
    }

    private func previewTileSize() -> CGFloat {
        switch Settings.libraryType {
        case .list:
            return 60
        case .fourByFour:
            return 100
        case .threeByThree:
            return 120
        }
    }
}

struct ColorPreviewFolderView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPreviewFolderView(model: FolderModel(), dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
            .previewLayout(.sizeThatFits)
    }
}
