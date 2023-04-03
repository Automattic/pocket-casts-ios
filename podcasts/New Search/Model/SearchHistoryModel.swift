import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import Combine

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

    private var notifications = Set<AnyCancellable>()

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.defaults = userDefaults

        self.entries = userDefaults.data(forKey: Constants.UserDefaults.searchHistoryEntries).flatMap {
            try? JSONDecoder().decode([SearchHistoryEntry].self, from: $0)
        } ?? []

        addNotificationObservers()
        updateFolders()
    }

    private func addNotificationObservers() {
        let notificationCenter = NotificationCenter.default

        // Listen for folder and subscription changes
        Publishers.Merge(
            notificationCenter.publisher(for: ServerNotifications.subscriptionStatusChanged),
            notificationCenter.publisher(for: Constants.Notifications.folderEdited)
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.updateFolders()
        }
        .store(in: &notifications)

        // Listen for folder deletion changes
        notificationCenter.publisher(for: Constants.Notifications.folderDeleted)
            .receive(on: RunLoop.main)
            .compactMap { $0.object as? String }
            .sink { [weak self] uuid in
                self?.folderDeleted(uuid)
            }
            .store(in: &notifications)
    }

    private func updateFolders() {
        guard SubscriptionHelper.hasActiveSubscription() else {
            // User is not subscribed anymore, remove all folders from search history
            entries = entries.filter { $0.podcast?.kind != .folder }
            save()
            return
        }

        // A folder was changed, update all folders inside the search history
        entries = entries.compactMap { entry in
            if entry.podcast?.kind == .folder, let uuid = entry.podcast?.uuid {
                return DataManager.sharedManager.findFolder(uuid: uuid).map {
                    SearchHistoryEntry(podcast: PodcastFolderSearchResult(from: $0))
                }
            }

            return entry
        }

        save()
    }

    private func folderDeleted(_ uuid: String) {
        entries = entries.filter { $0.podcast?.uuid != uuid }
        save()
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

    func moveEntryToTop(_ entry: SearchHistoryEntry) {
        add(entry: entry)
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
        let updatedEntries = Array(entries.prefix(maxNumberOfEntries))

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(updatedEntries) {
            defaults.set(encoded, forKey: Constants.UserDefaults.searchHistoryEntries)
            entries = updatedEntries
        }
    }
}
