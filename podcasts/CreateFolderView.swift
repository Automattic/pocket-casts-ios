import PocketCastsDataModel
import SwiftUI

struct CreateFolderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject private var pickerModel = PodcastPickerModel()
    @ObservedObject private var model = FolderModel()

    var dismissAction: (String?) -> Void

    var preselectPodcastUuid: String?

    var addButtonTitle: String {
        let selectedCount = pickerModel.selectedPodcastUuids.count
        if selectedCount == 1 {
            return L10n.folderAddPodcastsSingular
        } else {
            return L10n.folderAddPodcastsPluralFormat(selectedCount)
        }
    }

    var body: some View {
        if let _ = preselectPodcastUuid {
            mainBody
        } else {
            navWrappedBody
        }
    }

    var mainBody: some View {
        VStack {
            PodcastPickerView(pickerModel: pickerModel)
            NavigationLink(destination: NameFolderView(model: model, dismissAction: dismissAction, numberOfSelectedPodcasts: pickerModel.selectedPodcastUuids.count)) {
                Text(addButtonTitle)
                    .textStyle(RoundedButton())
            }
            .padding(.horizontal)
        }
        .navigationTitle(L10n.folderCreate)
        .onAppear {
            pickerModel.setup()
            if let uuid = preselectPodcastUuid {
                pickerModel.selectedPodcastUuids.append(uuid)
            }
            Analytics.track(.folderCreateShown, properties: ["source": analyticsSource])
        }
        .onDisappear {
            model.selectedPodcastUuids = pickerModel.selectedPodcastUuids
        }
        .applyDefaultThemeOptions()
    }

    var navWrappedBody: some View {
        NavigationView {
            mainBody
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            pickerModel.toggleSelectAll()
                        } label: {
                            Text(pickerModel.hasSelectedAll ? L10n.deselectAll : L10n.selectAll)
                        }
                        .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    /// From when the flow was initiated
    var analyticsSource: AnalyticsSource {
        preselectPodcastUuid != nil ? .chooseFolder : .podcastsList
    }
}

struct CreateFolderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateFolderView(dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
