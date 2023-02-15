import Foundation
import PocketCastsDataModel
import PocketCastsUtils

struct BookmarkManager {
    private let dataManager = DataManager.sharedManager.bookmarks
    /// How long a bookmark clip is
    /// TODO: Make configurable
    private let clipLength = 1.minute
    func bookmarks(for podcast: Podcast) -> [Bookmark] {
