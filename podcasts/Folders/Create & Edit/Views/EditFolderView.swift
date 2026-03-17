import SwiftUI

struct EditFolderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var model: FolderModel

    var dismissAction: (Bool) -> Void

    @State var showingDeleteConfirmation = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Group {
                    Text(L10n.name.localizedUppercase)
                        .textStyle(SecondaryText())
                        .font(.subheadline)
                        .padding(.bottom, -8)
                        .padding(.top, 30)
                    TextField("", text: $model.name)
                        .onChange(of: model.name, perform: model.validateFolderName)
                        .themedTextField()
                }
                .padding(.bottom, 10)
                .padding([.leading, .trailing], 16)
                VStack(alignment: .leading, spacing: 20) {
                    Text(L10n.color.localizedUppercase)
                        .textStyle(SecondaryText())
                        .font(.subheadline)
                        .padding(.bottom, -14)
                        .padding([.leading, .trailing], 16)
                    ThemedDivider()
                    ColorSelectRow(model: model)
                        .padding([.leading, .trailing], 16)
                }
                .padding(.vertical, 10)
                ThemedDivider()
                    .padding(.bottom, 16)
                VStack(alignment: .leading, spacing: 15) {
                    ThemedDivider()
                    Button {
                        showingDeleteConfirmation = true
                        Analytics.track(.folderEditDeleteButtonTapped)
                    } label: {
                        Group {
                            Image("delete")
                            Text(L10n.folderDelete)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .foregroundColor(ThemeColor.support05(for: theme.activeTheme).color)
                        .padding(.leading, 16)
                    }
                    .alert(isPresented: $showingDeleteConfirmation) {
                        Alert(
                            title: Text(L10n.folderDeletePromptTitle),
                            message: Text(L10n.folderDeletePromptMsg),
                            primaryButton: .destructive(Text(L10n.delete)) {
                                model.deleteFolder()
                                Analytics.track(.folderDeleted)
                                dismissAction(true)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    ThemedDivider()
                }
                .padding(.top, 10)
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismissAction(false)
                    } label: {
                        Image("close")
                            .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                    }
                    .accessibilityLabel(L10n.close)
                }
            }
            .onAppear {
                Analytics.track(.folderEditShown)
            }
            .onDisappear {
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: model.folderUuid)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderEdited, object: model.folderUuid)
                Analytics.track(.folderEditDismissed, properties: ["did_change_name": model.didChangeName, "did_change_color": model.didChangeColor])
            }
            .applyDefaultThemeOptions()
            .navigationTitle(L10n.folderEdit)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct EditFolderView_Previews: PreviewProvider {
    static var previews: some View {
        EditFolderView(model: FolderModel(), dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
            .previewOnAllDevices()
    }
}
