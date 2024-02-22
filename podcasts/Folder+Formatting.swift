import Foundation
import PocketCastsDataModel

extension Folder {
    func librarySort() -> LibrarySort {
        LibrarySort(oldValue: Int(sortType)) ?? .dateAddedNewestToOldest
    }
}
