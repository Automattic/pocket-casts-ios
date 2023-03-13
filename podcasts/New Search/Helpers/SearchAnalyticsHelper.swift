import SwiftUI

class SearchAnalyticsHelper: ObservableObject {
    let source: AnalyticsSource

    init(source: AnalyticsSource) {
        self.source = source
    }

    // MARK: - Search History

    func trackHistoryCleared() {
        Analytics.track(.searchHistoryCleared, properties: ["source": source])
    }

    func historyItemTapped(_ entry: SearchHistoryEntry) {
        let uuid = entry.podcast?.uuid ?? entry.episode?.uuid ?? ""
        Analytics.track(.searchHistoryItemTapped, properties: ["source": source, "uuid": uuid, "type": entry.type])
    }
}

private extension SearchHistoryEntry {
    var type: String {
        if podcast?.isFolder == true {
            return "folder"
        } else if podcast != nil {
            return "podcast"
        } else if episode != nil {
            return "episode"
        } else {
            return "search_term"
        }
    }
}
