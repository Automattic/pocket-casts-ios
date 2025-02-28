import SwiftUI

enum SuggestedFoldersResult {
    case dismiss
    case applySuggestedFolders([SuggestedFolder])
    case createdManualFolder(String)
}

struct SuggestedFoldersView: View {

    enum Constants {
        static var margin: CGFloat = 20
    }

    @EnvironmentObject var theme: Theme
    @State private var createFolderActive = false
    @ObservedObject var model: SuggestedFoldersModel = SuggestedFoldersModel()

    var onCompletion: (SuggestedFoldersResult) -> Void

    var body: some View {
        Group {
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
                                    onCompletion(.dismiss)
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
            case .failed:
                CreateFolderView(isInsideNavigation: false) { uuid in
                    if let uuid {
                        onCompletion(.createdManualFolder(uuid))
                    } else {
                        onCompletion(.dismiss)
                    }
                }
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
                onCompletion(.applySuggestedFolders(model.folders))
            } label: {
                Text(L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
            NavigationLink(destination: CreateFolderView(isInsideNavigation: true) { uuid in
                if let uuid {
                    onCompletion(.createdManualFolder(uuid))
                } else {
                    onCompletion(.dismiss)
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
        SuggestedFoldersView(onCompletion: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
