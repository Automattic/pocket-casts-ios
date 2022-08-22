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
            return L10n.Localizable.folderAddPodcastsSingular
        }
        else {
            return L10n.Localizable.folderAddPodcastsPluralFormat(selectedCount)
        }
    }
    
    var body: some View {
        if let _ = preselectPodcastUuid {
            mainBody
        }
        else {
            navWrappedBody
        }
    }
    
    var mainBody: some View {
        VStack {
            PodcastPickerView(pickerModel: pickerModel)
            NavigationLink(destination: NameFolderView(model: model, dismissAction: dismissAction)) {
                Text(addButtonTitle)
                    .textStyle(RoundedButton())
            }
        }
        .padding()
        .navigationTitle(L10n.Localizable.folderCreate)
        .onAppear {
            pickerModel.setup()
            if let uuid = preselectPodcastUuid {
                pickerModel.selectedPodcastUuids.append(uuid)
            }
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
                        .accessibilityLabel(L10n.Localizable.close)
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct CreateFolderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateFolderView(dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
