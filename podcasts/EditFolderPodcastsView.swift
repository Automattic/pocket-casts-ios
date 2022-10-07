import SwiftUI

struct EditFolderPodcastsView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model: FolderModel
    @ObservedObject private var pickerModel = PodcastPickerModel()

    var dismissAction: () -> Void

    var body: some View {
        NavigationView {
            PodcastPickerView(pickerModel: pickerModel)
                .navigationTitle(L10n.folderChoosePodcasts)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismissAction()
                        } label: {
                            Image("close")
                                .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                        }
                        .accessibilityLabel(L10n.close)
                    }
                }
                .applyDefaultThemeOptions()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            pickerModel.pickingForFolderUuid = model.folderUuid
            pickerModel.selectedPodcastUuids = model.selectedPodcastUuids
            pickerModel.setup()
            Analytics.track(.folderChoosePodcastsShown)
        }
        .onDisappear {
            let numberOfPodcastsChanged = pickerModel.selectedPodcastUuids.count - model.selectedPodcastUuids.count
            Analytics.track(.folderChoosePodcastsDismissed, properties: ["changed_podcasts": numberOfPodcastsChanged])
            model.selectedPodcastUuids = pickerModel.selectedPodcastUuids
        }
    }
}

struct EditFolderPodcastsView_Previews: PreviewProvider {
    static var previews: some View {
        EditFolderPodcastsView(model: FolderModel()) {}
            .environmentObject(Theme(previewTheme: .light))
    }
}
