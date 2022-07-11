import Foundation
import PocketCastsDataModel

extension Folder {
    func librarySort() -> LibrarySort {
        LibrarySort(rawValue: Int(sortType)) ?? .dateAddedNewestToOldest
    }
}
