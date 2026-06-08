import Foundation
import PocketCastsDataModel

class HomeGridItem: Identifiable {
    let podcast: Podcast?
    let folder: Folder?

    enum ID: Hashable {
        case podcast(String)
        case folder(String)
        case empty
    }

    var id: ID {
        if let podcast {
            return .podcast(podcast.uuid)
        } else if let folder {
            return .folder(folder.uuid)
        }
        return .empty
    }

    init(podcast: Podcast) {
        self.podcast = podcast
        folder = nil
    }

    init(folder: Folder) {
        self.folder = folder
        podcast = nil
    }
}
