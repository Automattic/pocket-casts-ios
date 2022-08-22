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
                    Text(L10n.Localizable.name.localizedUppercase)
                        .textStyle(SecondaryText())
                        .font(.subheadline)
                        .padding(.bottom, -8)
                    TextField("", text: $model.name)
                        .onChange(of: model.name, perform: model.validateFolderName)
                        .themedTextField()
                }
                .padding(.bottom, 10)
                VStack(alignment: .leading, spacing: 20) {
                    Text(L10n.Localizable.color.localizedUppercase)
                        .textStyle(SecondaryText())
                        .font(.subheadline)
                        .padding(.bottom, -14)
                    ThemedDivider()
                    ColorSelectRow(model: model)
                }
                .padding(.vertical, 10)
                ThemedDivider()
                VStack(alignment: .leading, spacing: 20) {
                    ThemedDivider()
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Group {
                            Image("delete")
                            Text(L10n.Localizable.folderDelete)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .foregroundColor(ThemeColor.support05(for: theme.activeTheme).color)
                        .padding(.leading, 6)
                    }
                    .alert(isPresented: $showingDeleteConfirmation) {
                        Alert(
                            title: Text(L10n.Localizable.folderDeletePromptTitle),
                            message: Text(L10n.Localizable.folderDeletePromptMsg),
                            primaryButton: .destructive(Text(L10n.Localizable.delete)) {
                                model.deleteFolder()
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
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismissAction(false)
                    } label: {
                        Image("close")
                            .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                    }
                    .accessibilityLabel(L10n.Localizable.close)
                }
            }
            .onDisappear {
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: model.folderUuid)
            }
            .applyDefaultThemeOptions()
            .navigationTitle(L10n.Localizable.folderEdit)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
