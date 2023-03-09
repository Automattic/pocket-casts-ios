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

    func add(entry: SearchHistoryEntry) {
        entries.removeAll(where: { $0 == entry })
        entries.insert(entry, at: 0)

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(entries) {
            defaults.set(encoded, forKey: "SearchHistoryEntries")
        }
    }

    func remove(entry: SearchHistoryEntry) {
        entries.removeAll(where: { $0 == entry })

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(entries) {
            defaults.set(encoded, forKey: "SearchHistoryEntries")
        }
    }

    func removeAll() {
        entries = []

        UserDefaults.standard.removeObject(forKey: "SearchHistoryEntries")
    }
}
