import Foundation

@testable import PocketCastsDataModel

/// Creates a Folder with a random `uuid`
class FolderBuilder {
    let folder: Folder

    init() {
        folder = Folder()
        folder.uuid = NSUUID().uuidString
    }

    /// Add the given list of podcasts to this folder
    func with(podcasts: [Podcast]) -> FolderBuilder {
        podcasts.forEach { $0.folderUuid = folder.uuid }
        return self
    }

    func with(name: String) -> Self {
        folder.name = name
        return self
    }

    func build() -> Folder {
        folder
    }
}
