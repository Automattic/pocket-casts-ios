import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct SuggestedFolder: Identifiable {
    var id: String {
        return name
    }

    let name: String
    let color: Int32
    let podcastUuids: [String]
}

class SuggestedFoldersModel: ObservableObject {

    @Published var folders: [SuggestedFolder] = []

    enum State {
        case start
        case loading
        case loaded
        case failed
    }

    @Published var loadingState: State = .start

    let dataManager: DataManager

    var failedToLoadAction: (() -> ())? = nil

    var previousUuids: [String] = []

    init(dataManager: DataManager = DataManager.sharedManager, failedToLoadAction: (() -> ())? = nil) {
        self.dataManager = dataManager
        self.failedToLoadAction = failedToLoadAction
    }

    func load() async {
        if loadingState == .loading {
            return
        }
        Task { @MainActor in
            loadingState = .loading
            let uuids = dataManager.allPodcastsOrderedByAddedDate().map { $0.uuid }
            if areUuidsTheSame(previous: previousUuids, current: uuids) {
                loadingState = .loaded
                return
            }
            previousUuids = uuids
            guard let suggestionsResponse = await ApiServerHandler.shared.suggestedFolders(for: uuids) else {
                loadingState = .failed
                failedToLoadAction?()
                return
            }
            var folders = [SuggestedFolder]()
            for suggestion in suggestionsResponse.suggestions.keys.sorted() {
                if let uuids = suggestionsResponse.suggestions[suggestion] {
                    let folder = SuggestedFolder(name: suggestion, color: Int32.random(in: 0..<12), podcastUuids: uuids)
                    folders.append(folder)
                }
            }
            self.folders = folders
            loadingState = .loaded
        }
    }

    private func areUuidsTheSame(previous: [String], current: [String]) -> Bool {
        return previous == current
    }

    var userHasSubscription: Bool {
        return SubscriptionHelper.hasActiveSubscription()
    }

    var showConfirmation: Bool {
        return userHasExistingFolders && SubscriptionHelper.hasActiveSubscription()
    }

    var userHasExistingFolders: Bool {
        return dataManager.allFolders().count > 0
    }

    var userIsSignedIn: Bool {
        return SyncManager.isUserLoggedIn()
    }

    var userType: String {
        var userType = "unsigned"
        if userIsSignedIn {
            userType = "free"
        }
        if userHasSubscription {
            userType = "paid"
        }
        return userType
    }
}
