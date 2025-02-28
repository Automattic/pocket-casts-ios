import PocketCastsDataModel
import SwiftUI
import PocketCastsServer

class SuggestedFoldersModel: ObservableObject {

    @Published var folders: [SuggestedFolder] = []

    enum State {
        case start
        case loading
        case loaded
        case failed
    }

    @Published var loadingState: State = .start

    var failedToLoadAction: (() -> ())? = nil

    init(failedToLoadAction: (() -> ())? = nil) {
        self.failedToLoadAction = failedToLoadAction
    }

    func load() async {
        if loadingState != .start {
            return
        }
        loadingState = .loading
        Task { @MainActor in
            let uuids = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false).map { $0.uuid }
            guard let suggestionsResponse = await ApiServerHandler.shared.suggestedFolders(for: uuids) else {
                loadingState = .failed
                failedToLoadAction?()
                return
            }
            var folders = [SuggestedFolder]()
            for suggestion in suggestionsResponse.suggestions.keys.sorted() {
                if let uuids = suggestionsResponse.suggestions[suggestion] {
                    let folder = SuggestedFolder(name: suggestion, color: Int32.random(in: 0..<10), topPodcastUuids: uuids)
                    folders.append(folder)
                }
            }
            self.folders = folders
            loadingState = .loaded
        }
    }
}

struct SuggestedFoldersView: View {

    enum Constants {
        static var margin: CGFloat = 20
    }

    @EnvironmentObject var theme: Theme
    @State private var createFolderActive = false
    @ObservedObject var model: SuggestedFoldersModel = SuggestedFoldersModel()

    var dismissAction: (String?) -> Void

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
                                    dismissAction(nil)
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
                CreateFolderView(isInsideNavigation: false, dismissAction: dismissAction)
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
                dismissAction(nil)
            } label: {
                Text(L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
            NavigationLink(destination: CreateFolderView(isInsideNavigation: true) { uuid in
                dismissAction(uuid)
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
        SuggestedFoldersView(dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
