import PocketCastsDataModel
import SwiftUI

struct SuggestedFolder {
    let name: String
    let color: Int32
    let topPodcastUuids: [String]
}

struct SuggestedFoldersView: View {
    @EnvironmentObject var theme: Theme
    @State private var createFolderActive = false

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
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 150))], alignment: .center, spacing: 6) {
                ForEach(0..<100) { index in
                    SuggestedFolderPreviewWrapper(folder: SuggestedFolder(name: "Folder-\(index)", color: Int32(index), topPodcastUuids: []))
                        .cornerRadius(4)
                        .frame(minWidth: 110, maxWidth: 150)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
}

struct SuggestedFoldersView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestedFoldersView(dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
