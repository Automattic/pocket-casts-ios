import Foundation
import PocketCastsDataModel
import PocketCastsUtils

struct BookmarkManager {
    private let dataManager = DataManager.sharedManager.bookmarks
    func bookmarks(for podcast: Podcast) -> [Bookmark] {
