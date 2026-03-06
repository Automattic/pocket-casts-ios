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

    let source: AnalyticsSource

    var onCompletion: (SuggestedFoldersResult) -> Void

    init(model: SuggestedFoldersModel = SuggestedFoldersModel(), source: AnalyticsSource, onCompletion: @escaping (SuggestedFoldersResult) -> Void) {
        self.model = model
        self.source = source
        self.onCompletion = onCompletion
    }

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
                                    track(.suggestedFoldersPageDismissed)
                                    onCompletion(.dismiss)
                                } label: {
                                    Image("close")
                                        .foregroundColor(ThemeColor.primaryInteractive01(for: theme.activeTheme).color)
                                }
                                .accessibilityLabel(L10n.close)
                            }
                        }
                }
                .navigationViewStyle(.stack)
                .tint(ThemeColor.primaryInteractive01(for: theme.activeTheme).color)
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
                Text(model.userHasExistingFolders ? L10n.suggestedFoldersDescriptionWithExistingFolders : L10n.suggestedFoldersDescription)
                    .textStyle(SecondaryText())
                    .font(.body)
            }
            foldersView
                .padding(.horizontal, -Constants.margin)
                // hack to allow the scroll indicator to be visible without overlapping the content
                .customHorizontalMargin(margin: Constants.margin)
            Button {
                if model.showConfirmation {
                    track(.suggestedFoldersReplaceFoldersTapped)
                    applySuggestedFoldersConfirmation.toggle()
                } else {
                    track(.suggestedFoldersUseSuggestedFoldersTapped)
                    onCompletion(.applySuggestedFolders(model.folders))
                }
            } label: {
                Text(model.userHasExistingFolders ? L10n.suggestedFoldersReplaceConfirmationButton : L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
            if model.userHasSubscription {
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
            } else {
                Button {
                    track(.suggestedFoldersCreateCustomFolderTapped)
                    onCompletion(.createdManualFolder(""))
                } label: {
                    Text(L10n.suggestedFoldersCreateCustomFolder)
                        .textStyle(BorderButton())
                }
            }
            Spacer()
        }
        .padding(.horizontal, Constants.margin)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            track(.suggestedFoldersPageShown)
        }
        .onChange(of: createFolderActive) { newFolder in
            if newFolder {
                track(.suggestedFoldersCreateCustomFolderTapped)
            }
        }
        .applyDefaultThemeOptions()
        .sheet(isPresented: $applySuggestedFoldersConfirmation) {
            confirmationModal
        }
    }

    var foldersView: some View {
        GridFoldersView(folders: model.folders, source: .unknown)
    }

    private var confirmationModal: some View {
        ModalMessageView(icon: "switch", title: L10n.suggestedFoldersReplaceConfirmationTitle, message: L10n.suggestedFoldersReplaceConfirmationDetails, destructive: true, actionTitle: L10n.suggestedFoldersReplaceConfirmationButton,
                         action: {
            applySuggestedFoldersConfirmation = false
            track(.suggestedFoldersReplaceFoldersConfirmTapped)
            onCompletion(.applySuggestedFolders(model.folders))
        })
        .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
    }

    private func track(_ event: AnalyticsEvent) {
        Analytics.track(event, properties: ["source": source.rawValue, "user_type": model.userType])
    }
}

struct SuggestedFoldersView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestedFoldersView(source: .unknown, onCompletion: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
