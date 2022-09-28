import Foundation
import PocketCastsDataModel

class HomeGridItem: Identifiable {
    let podcast: Podcast?
    let folder: Folder?

    init(podcast: Podcast) {
        self.podcast = podcast
        folder = nil
    }

    init(folder: Folder) {
        self.folder = folder
        podcast = nil
    }
}
