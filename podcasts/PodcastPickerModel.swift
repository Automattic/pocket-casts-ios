import Foundation
import PocketCastsDataModel

class PodcastPickerModel: ObservableObject {
    @Published var selectedPodcastUuids: [String] = []
    @Published var allPodcasts: [Podcast] = []
    @Published var filteredPodcasts: [Podcast] = []
    @Published var pickingForFolderUuid: String?

    enum PickerSortingStrategy {
        case none, foldersAtBottom
    }

    @Published var sortingStrategy: PickerSortingStrategy = .foldersAtBottom

    @Published var sortType: LibrarySort = .titleAtoZ {
        didSet {
            UserDefaults.standard.set(sortType.old.rawValue, forKey: Constants.UserDefaults.lastPickerSort)
            loadPodcasts()
        }
    }

    @Published var searchTerm = "" {
        willSet {
            trackSearchIfNeeded(oldValue: searchTerm, newValue: newValue)
        }

        didSet {
            filterPodcasts()
        }
    }

    var hasSelectedAll: Bool {
        selectedPodcastUuids.count == allPodcasts.count
    }

    func setup() {
        let savedSortTypeInt = UserDefaults.standard.integer(forKey: Constants.UserDefaults.lastPickerSort)
        if savedSortTypeInt != 0 {
            sortType = LibrarySort(oldValue: savedSortTypeInt) ?? .titleAtoZ
        }

        loadPodcasts()
    }

    private func loadPodcasts() {
        var podcasts = PodcastManager.shared.allPodcastsSorted(in: sortType)

        // filter podcasts in folders to the bottom, but not ones in the picking folder
        if sortingStrategy == .foldersAtBottom {
            podcasts.sort { podcast1, podcast2 in
                podcast2.folderUuid != nil && podcast2.folderUuid != pickingForFolderUuid && (podcast1.folderUuid == nil || podcast1.folderUuid == pickingForFolderUuid)
            }
        }

        allPodcasts = podcasts
        filterPodcasts()
    }

    func togglePodcastSelected(_ podcast: Podcast) {
        if let selectedIndex = selectedPodcastUuids.firstIndex(of: podcast.uuid) {
            selectedPodcastUuids.remove(at: selectedIndex)
        } else {
            selectedPodcastUuids.append(podcast.uuid)
        }
    }

    func toggleSelectAll() {
        if hasSelectedAll {
            selectedPodcastUuids.removeAll()
        } else {
            selectedPodcastUuids = allPodcasts.map { $0.uuid }
        }
    }

    private func filterPodcasts() {
        if searchTerm.isEmpty {
            filteredPodcasts = allPodcasts

            return
        }

        filteredPodcasts = allPodcasts.filter { ($0.title?.localizedCaseInsensitiveContains(searchTerm) ?? false) || ($0.author?.localizedCaseInsensitiveContains(searchTerm) ?? false) }
    }
}

// - MARK: Analytics

extension PodcastPickerModel {
    func trackSearchIfNeeded(oldValue: String, newValue: String) {
        if oldValue.count == 0 && newValue.count > 0 {
            Analytics.track(.folderPodcastPickerSearchPerformed)
        } else if oldValue.count > 0 && newValue.count == 0 {
            Analytics.track(.folderPodcastPickerSearchCleared)
        }
    }
}
