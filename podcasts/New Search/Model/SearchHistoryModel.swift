import SwiftUI
import PocketCastsServer

struct SearchHistoryEntry: Codable, Hashable {
    var searchTerm: String?
    var episode: EpisodeSearchResult?
    var podcast: PodcastSearchResult?
}

class SearchHistoryModel: ObservableObject {
    @Published var entries: [SearchHistoryEntry] = []

    let defaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.defaults = userDefaults

        if let entriesData = defaults.object(forKey: "SearchHistoryEntries") as? Data {
            let decoder = JSONDecoder()
            if let entries = try? decoder.decode([SearchHistoryEntry].self, from: entriesData) {
                self.entries = entries
            }
        }
    }

    func add(searchTerm: String) {
        add(entry: SearchHistoryEntry(searchTerm: searchTerm))
    }

    func add(episode: EpisodeSearchResult) {
        add(entry: SearchHistoryEntry(episode: episode))
    }

    func add(podcast: PodcastSearchResult) {
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
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(entries) {
            defaults.set(encoded, forKey: "SearchHistoryEntries")
        }
    }
}
