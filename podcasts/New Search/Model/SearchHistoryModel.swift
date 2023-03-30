import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct SearchHistoryEntry: Codable, Hashable {
    var searchTerm: String?
    var episode: EpisodeSearchResult?
    var podcast: PodcastFolderSearchResult?
}

class SearchHistoryModel: ObservableObject {
    static let shared = SearchHistoryModel()

    @Published var entries: [SearchHistoryEntry] = []

    private let defaults: UserDefaults
    private let maxNumberOfEntries = 20

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.defaults = userDefaults

        self.entries = userDefaults.data(forKey: "SearchHistoryEntries").flatMap {
            try? JSONDecoder().decode([SearchHistoryEntry].self, from: $0)
        } ?? []

        NotificationCenter.default.addObserver(self, selector: #selector(updateFolders), name: ServerNotifications.subscriptionStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFolders), name: Constants.Notifications.folderChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(folderDeleted), name: Constants.Notifications.folderDeleted, object: nil)

        updateFolders()
    }

    @objc private func updateFolders() {
        guard SubscriptionHelper.hasActiveSubscription() else {
            // User is not subscribed anymore, remove all folders from search history
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }

                self.entries = self.entries.filter { $0.podcast?.kind != .folder }
            }
            save()
            return
        }

        // A folder was changed, update all folders inside the search history
        entries = entries.compactMap { entry in
            if entry.podcast?.kind == .folder, let uuid = entry.podcast?.uuid {
                if let folder = DataManager.sharedManager.findFolder(uuid: uuid) {
                    return SearchHistoryEntry(podcast: PodcastFolderSearchResult(from: folder))
                } else {
                    return nil
                }
            }

            return entry
        }
        save()
    }

    @objc private func folderDeleted(_ notification: NSNotification) {
        if let uuid = notification.object as? String {
            entries = entries.filter { $0.podcast?.uuid != uuid }
            save()
        }
    }

    func add(searchTerm: String) {
        add(entry: SearchHistoryEntry(searchTerm: searchTerm))
    }

    func add(episode: EpisodeSearchResult) {
        add(entry: SearchHistoryEntry(episode: episode))
    }

    func add(podcast: PodcastFolderSearchResult) {
        add(entry: SearchHistoryEntry(podcast: podcast))
    }

    func remove(entry: SearchHistoryEntry) {
        entries.removeAll(where: { $0 == entry })

        save()
    }

    func removeAll() {
        entries = []

        save()
    }

    private func add(entry: SearchHistoryEntry) {
        entries.removeAll(where: { $0 == entry })
        entries.insert(entry, at: 0)

        save()
    }

    private func save() {
        entries = Array(entries.prefix(maxNumberOfEntries))
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(entries) {
            defaults.set(encoded, forKey: Constants.UserDefaults.searchHistoryEntried)
        }
    }
}
