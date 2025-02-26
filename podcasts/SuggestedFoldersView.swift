import PocketCastsDataModel
import SwiftUI
import PocketCastsServer

class SuggestedFoldersModel: ObservableObject {

    private static let somePodcastsUUIDs = ["e7abe050-6cc7-0130-f8c5-723c91aeae46", "ba993300-d71c-0137-1e26-0acc26574db2", "4eb5b260-c933-0134-10da-25324e2a541d", "71a77ab0-c8bf-0136-7b94-27f978dac4db", "467b49a0-c657-0138-e72e-0acc26574db2"]

    @Published var folders: [SuggestedFolder] = []

    enum State {
        case start
        case loading
        case loaded
    }

    @Published var loadingState: State = .start

    init() {

    }

    func load() async {
        if loadingState == .loading {
            return
        }
        Task { @MainActor in
            loadingState = .loading
            guard let suggestionsResponse = await ApiServerHandler.shared.suggestedFolders(for: Self.somePodcastsUUIDs) else {
                return
            }
            var folders = [SuggestedFolder]()
            for suggestion in suggestionsResponse.suggestions.keys {
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
        .task {
            await model.load()
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
