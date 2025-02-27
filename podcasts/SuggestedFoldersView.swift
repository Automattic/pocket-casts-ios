import SwiftUI

struct SuggestedFoldersView: View {

    enum Constants {
        static var margin: CGFloat = 20
    }

    public enum FolderResult {
        case dismiss
        case createManualFolder(String)
        case createSuggestedFolders([SuggestedFolder])
    }

    @EnvironmentObject var theme: Theme
    @State private var createFolderActive = false
    @ObservedObject var model: SuggestedFoldersModel = SuggestedFoldersModel()

    var dismissAction: (FolderResult) -> ()

    init(completion: @escaping (FolderResult) -> ()) {
        self.dismissAction = completion
    }

    var body: some View {
        VStack {
            switch model.loadingState {
            case .start, .loading:
                loadingView
            case .loaded:
                NavigationContainer {
                    mainBody
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    Analytics.track(.suggestedFoldersModalDismissed, properties: [:])
                                    dismissAction(.dismiss)
                                } label: {
                                    Image("close")
                                        .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                                }
                                .accessibilityLabel(L10n.close)
                            }
                        }
                .navigationViewStyle(.stack)
                .tint(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
            }
            case .failed:
                CreateFolderView(isInsideNavigation: false, dismissAction: { uuid in
                    if let uuid {
                        dismissAction(.createManualFolder(uuid))
                    } else {
                        dismissAction(.dismiss)
                    }
                })
            }
        }
        .task {
            await model.load()
        }
    }

    var loadingView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                LoadingView()
                Spacer()
            }
            Spacer()
        }
        .applyDefaultThemeOptions()
    }

    var mainBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 8)
            Text(L10n.suggestedFoldersDescription)
                .textStyle(SecondaryText())
            foldersView
                .padding(.horizontal, -Constants.margin)
                // hack to allow the scroll indicator to be visible without overlapping the content
                .customHorizontalMargin(margin: Constants.margin)
            Button {
                Analytics.track(.suggestedFoldersModalUseTheseFoldersTapped, properties: [:])
                dismissAction(.createSuggestedFolders(model.folders))
            } label: {
                Text(L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
            NavigationLink(destination: CreateFolderView(isInsideNavigation: true) { uuid in
                if let uuid {
                    dismissAction(.createManualFolder(uuid))
                } else {
                    dismissAction(.dismiss)
                }
            }, isActive: $createFolderActive) {
                Text(L10n.suggestedFoldersCreateCustomFolders)
                    .textStyle(BorderButton())
            }
            Spacer()
        }
        .padding(.horizontal, Constants.margin)
        .navigationTitle(L10n.suggestedFoldersTitle)
        .onAppear {
            Analytics.track(.suggestedFoldersModalShow, properties: [:])
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
        SuggestedFoldersView(completion: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
