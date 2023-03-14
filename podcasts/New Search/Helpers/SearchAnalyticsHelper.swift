import SwiftUI
import PocketCastsServer

class SearchAnalyticsHelper: ObservableObject {
    let source: AnalyticsSource

    init(source: AnalyticsSource) {
        self.source = source
    }

    // MARK: - Search

    func trackShown() {
        Analytics.track(.searchShown, properties: ["source": source])
    }

    func trackDismissed() {
        Analytics.track(.searchDismissed, properties: ["source": source])
    }

    func trackSearchPerformed() {
        Analytics.track(.searchPerformed, properties: ["source": source])
    }

    func trackFailed() {
        Analytics.track(.searchFailed, properties: ["source": source])
    }

    func trackResultTapped(_ searchResult: Any) {
        var type = "unknown"
        var uuid = ""
        if let folderOrPodcast = searchResult as? PodcastFolderSearchResult {
            type = folderOrPodcast.type
            uuid = folderOrPodcast.uuid
        } else if let episode = searchResult as? EpisodeSearchResult {
            type = "episode"
            uuid = episode.uuid
        }
        Analytics.track(.searchResultTapped, properties: ["source": source, "uuid": uuid, "result_type": type])
    }

    // MARK: - Search History

    func trackHistoryCleared() {
        Analytics.track(.searchHistoryCleared, properties: ["source": source])
    }

    func historyItemTapped(_ entry: SearchHistoryEntry) {
        let uuid = entry.podcast?.uuid ?? entry.episode?.uuid ?? ""
        Analytics.track(.searchHistoryItemTapped, properties: ["source": source, "uuid": uuid, "type": entry.type])
    }

    func historyItemDeleted(_ entry: SearchHistoryEntry) {
        let uuid = entry.podcast?.uuid ?? entry.episode?.uuid ?? ""
        Analytics.track(.searchHistoryItemDeleteButtonTapped, properties: ["source": source, "uuid": uuid, "type": entry.type])
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

private extension PodcastFolderSearchResult {
    var type: String {
        if isFolder == true {
            return "folder"
        } else if isLocal == true {
            return "podcast_local_result"
        } else {
            return "podcast"
        }
    }
}
