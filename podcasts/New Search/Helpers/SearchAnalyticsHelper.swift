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

    func trackSearchPerformed() {
        Analytics.track(.searchPerformed, properties: ["source": source])
    }

    func trackFailed(_ error: Error) {
        Analytics.track(.searchFailed, properties: ["source": source, "error_code": (error as NSError).code])
    }

    func trackResultTapped(_ searchResult: AnalyticsSearchResultItem) {
        Analytics.track(.searchResultTapped, properties: ["source": source, "uuid": searchResult.uuid, "result_type": searchResult])
    }

    // MARK: - Search History

    func trackHistoryCleared() {
        Analytics.track(.searchHistoryCleared, properties: ["source": source])
    }

    func historyItemTapped(_ entry: AnalyticsSearchResultItem) {
        Analytics.track(.searchHistoryItemTapped, properties: ["source": source, "uuid": entry.uuid, "type": entry])
    }

    func historyItemDeleted(_ entry: AnalyticsSearchResultItem) {
        Analytics.track(.searchHistoryItemDeleteButtonTapped, properties: ["source": source, "uuid": entry.uuid, "type": entry])
    }

    // MARK: - Search list results

    func trackListShown(_ displaying: SearchResultsListView.DisplayMode) {
        Analytics.track(.searchListShown, properties: ["source": source, "displaying": displaying])
    }
}

protocol AnalyticsSearchResultItem: AnalyticsDescribable {
    var uuid: String { get }
}

extension EpisodeSearchResult: AnalyticsSearchResultItem {
    var analyticsDescription: String {
        "episode"
    }
}

extension PodcastFolderSearchResult: AnalyticsSearchResultItem {
    var analyticsDescription: String {
        if kind == .folder {
            return "folder"
        } else if isLocal == true {
            return "podcast_local_result"
        } else {
            return "podcast_remote_result"
        }
    }
}

extension SearchHistoryEntry: AnalyticsSearchResultItem {
    var uuid: String {
        podcast?.uuid ?? episode?.uuid ?? ""
    }

    var analyticsDescription: String {
        podcast?.analyticsDescription ?? episode?.analyticsDescription ?? "search_term"
    }
}
