import SwiftUI
import PocketCastsServer

struct SearchHistoryEntry: Codable {
    var searchTerm: String?
    var episode: EpisodeSearchResult?
    var podcast: PodcastSearchResult?
}

class SearchHistoryModel: ObservableObject {
    @Published var entries: [SearchHistoryEntry] = []

    let defaults = UserDefaults.standard

    init() {
        if let entriesData = defaults.object(forKey: "SearchHistoryEntries") as? Data {
            let decoder = JSONDecoder()
            if let entries = try? decoder.decode([SearchHistoryEntry].self, from: entriesData) {
                self.entries = entries
            }
        }
    }

    func add(entry: SearchHistoryEntry) {
        entries.insert(entry, at: 0)

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(entries) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "SearchHistoryEntries")
        }
    }
}
