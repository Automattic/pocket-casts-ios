import PocketCastsDataModel
import SwiftUI

class SuggestedFoldersModel: ObservableObject {

    var folders: [SuggestedFolder] = {
        let result: [SuggestedFolder] = (0..<10).map { index in
            SuggestedFolder(name: "Folder-\(index)", color: Int32(index), topPodcastUuids: [])
        }
        return result
    }()
}

struct SuggestedFoldersView: View {
    @EnvironmentObject var theme: Theme
    @State private var createFolderActive = false
    @ObservedObject var model: SuggestedFoldersModel = SuggestedFoldersModel()

    var dismissAction: (String?) -> Void

    var body: some View {
        NavigationView {
            mainBody
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            Analytics.track(.suggestedFoldersModalDismissed, properties: [:])
                            dismissAction(nil)
                        } label: {
                            Image("close")
                                .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                        }
                        .accessibilityLabel(L10n.close)
                    }
                }
        }
        .navigationViewStyle(.stack)
        .tint(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
    }

    var mainBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 8)
            Text(L10n.suggestedFoldersDescription)
                .textStyle(SecondaryText())
            foldersView
            Button {
                Analytics.track(.suggestedFoldersModalUseTheseFoldersTapped, properties: [:])
                dismissAction(nil)
            } label: {
                Text(L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
            NavigationLink(destination: CreateFolderView(isInsideNavigation: true) { uuid in
                dismissAction(uuid)
            }, isActive: $createFolderActive) {
                Text(L10n.suggestedFoldersCreateCustomFolders)
                    .textStyle(BorderButton())
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .navigationTitle(L10n.suggestedFoldersTitle)
        .onAppear {
            Analytics.track(.suggestedFoldersModalShow, properties: [:])
        }
        .onDisappear {

        }
        .onChange(of: createFolderActive) { newFolder in
            if newFolder {
                Analytics.track(.suggestedFoldersModalCreateCustomFoldersTapped, properties: [:])
            }
        }
        .applyDefaultThemeOptions()
    }

    var foldersView: some View {
        GridFoldersView(folders: model.folders)
    }
}

struct SuggestedFoldersView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestedFoldersView(dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
