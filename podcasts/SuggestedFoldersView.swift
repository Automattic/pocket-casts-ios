import SwiftUI

enum SuggestedFoldersResult {
    case dismiss
    case applySuggestedFolders([SuggestedFolder])
    case createdManualFolder(String)
}

struct SuggestedFoldersView: View {

    enum Constants {
        static var margin: CGFloat = 16
    }

    @EnvironmentObject var theme: Theme

    @State private var createFolderActive = false

    @State private var applySuggestedFoldersConfirmation = false

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
            Group {
                Text(L10n.suggestedFoldersTitle)
                    .textStyle(PrimaryText())
                    .font(.largeTitle.bold())
                Text(L10n.suggestedFoldersDescription)
                    .textStyle(SecondaryText())
                    .font(.body)
            }
            foldersView
                .padding(.horizontal, -Constants.margin)
                // hack to allow the scroll indicator to be visible without overlapping the content
                .customHorizontalMargin(margin: Constants.margin)
            Button {
                Analytics.track(.suggestedFoldersModalUseTheseFoldersTapped)
                Analytics.track(.suggestedFoldersReplaceExistingFoldersModalShown)
                if model.userHasExistingFolders {
                    applySuggestedFoldersConfirmation.toggle()
                } else {
                    onCompletion(.applySuggestedFolders(model.folders))
                }
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
                Text(L10n.suggestedFoldersCreateCustomFolder)
                    .textStyle(BorderButton())
            }
            Spacer()
        }
        .padding(.horizontal, Constants.margin)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Analytics.track(.suggestedFoldersModalShow, properties: [:])
        }
        .onChange(of: createFolderActive) { newFolder in
            if newFolder {
                Analytics.track(.suggestedFoldersModalCreateCustomFoldersTapped, properties: [:])
            }
        }
        .applyDefaultThemeOptions()
        .sheet(isPresented: $applySuggestedFoldersConfirmation) {
            confirmationModal
        }
    }

    var foldersView: some View {
        GridFoldersView(folders: model.folders)
    }

    private var confirmationModal: some View {
        ModalMessageView(icon: "switch", title: L10n.suggestedFoldersReplaceConfirmationTitle, message: L10n.suggestedFoldersReplaceConfirmationDetails, destructive: true, actionTitle: L10n.suggestedFoldersReplaceConfirmationButton,
                         action: {
            applySuggestedFoldersConfirmation = false
            Analytics.track(.suggestedFoldersReplaceFoldersTapped)
            onCompletion(.applySuggestedFolders(model.folders))
        })
        .modify {
            if #available(iOS 16.0, *) {
                $0.presentationDetents([.fraction(0.35)])
                    .presentationDragIndicator(.visible)
            } else {
                $0
            }
        }
    }
}

struct SuggestedFoldersView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestedFoldersView(onCompletion: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
