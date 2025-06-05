import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct SuggestedFolder: Identifiable, Codable {
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
            if loadingState == .start {
                loadFromCache()
            }
            loadingState = .loading
            let uuids = dataManager.allPodcastsOrderedByAddedDate().map { $0.uuid }.sorted()
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
            saveToCache()
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

    private lazy var cacheLocation: URL = {
        let fileManager: FileManager = .default
        let name: String = "suggestedFolders"

        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        return fileURL
    }()

    private func saveToCache() {
        let fileURL = cacheLocation
        guard let data = try? JSONEncoder().encode(folders) else {
            return
        }
        try? data.write(to: fileURL)
    }

    private func loadFromCache() {
        let fileURL = cacheLocation
        guard let data = try? Data(contentsOf: fileURL),
              let folders = try? JSONDecoder().decode([SuggestedFolder].self, from: data) else {
            return
        }
        var previousUuids = folders.reduce(into: [String]()) { result, folder in
            result.append(contentsOf: folder.podcastUuids)
        }
        self.folders = folders
        self.previousUuids = previousUuids.sorted()
    }
}
