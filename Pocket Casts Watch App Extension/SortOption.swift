import Foundation
import PocketCastsDataModel

protocol SortOption: Identifiable, CaseIterable, Equatable {
    static var pickerTitle: String { get }
    var description: String { get }
}

extension PodcastEpisodeSortOrder: SortOption {
    static var pickerTitle: String = L10n.sortEpisodes

    var id: Int32 { rawValue }
}

extension LibrarySort: SortOption {
    static var pickerTitle: String = L10n.podcastsSort
    var id: Int { rawValue }

    static var allCases: [LibrarySort] {
        [.dateAddedNewestToOldest, .titleAtoZ, .episodeDateNewestToOldest] // custom not available on watch
    }
}

extension UploadedSort: SortOption {
    static var pickerTitle: String = L10n.filesSort
    public var id: Int { rawValue }
}
