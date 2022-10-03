import PocketCastsDataModel
import SwiftUI

struct ChoosePodcastFolderView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var model: ChoosePodcastFolderModel

    var dismissAction: (String?) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ThemedDivider()
                    ForEach(model.availableFolders) { folder in
                        Button {
                            model.movePodcastToFolder(folder)
                            dismissAction(folder.uuid)
                            trackFolderTappedIfNeeded()
                        } label: {
                            FolderSelectRow(model: model, folder: folder)
                        }
                        ThemedDivider()
                    }
                    HStack {
                        Spacer()
                        NavigationLink(destination: CreateFolderView(dismissAction: dismissAction, preselectPodcastUuid: model.pickingForPodcastUuid)) {
                            HStack {
                                Image(systemName: "plus")
                                Text(L10n.folderNew)
                                    .fontWeight(.semibold)
                            }
                            .font(.callout)
                            .foregroundColor(ThemeColor.primaryInteractive01(for: theme.activeTheme).color)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ThemeColor.primaryInteractive01(for: theme.activeTheme).color, lineWidth: 2)
                            )
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.top, 14)
            .navigationTitle(L10n.folderPodcastChooseFolder)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismissAction(nil)
                    } label: {
                        Image("close")
                            .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                    }
                    .accessibilityLabel(L10n.close)
                }
            }
            .applyDefaultThemeOptions()
            .onAppear {
                model.loadFolders()
                Analytics.track(.folderChooseShown)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

extension ChoosePodcastFolderView {
    func trackFolderTappedIfNeeded() {
        if model.didMoveToFolder {
            Analytics.track(.folderChooseFolderTapped)
        } else if model.didRemoveFromFolder {
            Analytics.track(.folderChooseRemovedFromFolder)
        }
    }
}

struct FolderSelectRow: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var model: ChoosePodcastFolderModel
    @State var folder: Folder

    var body: some View {
        HStack(spacing: 16) {
            if let color = model.colorForFolder(folder: folder) {
                Image("folder-empty")
                    .foregroundColor(color)
            } else {
                Spacer()
                    .frame(width: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(model.nameForFolder(folder: folder))
                    .textStyle(PrimaryText())
                    .font(.headline)
                    .lineLimit(1)
                Text(L10n.podcastCount(model.podcastCountForFolder(folder: folder)))
                    .textStyle(SecondaryText())
                    .font(.footnote)
                    .lineLimit(1)
            }
            Spacer()
            if folder.uuid == model.currentFolder {
                Image("small-tick")
                    .foregroundColor(ThemeColor.primaryIcon01(for: theme.activeTheme).color)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
    }
}
