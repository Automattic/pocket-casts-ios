import PocketCastsDataModel
import PocketCastsServer

extension PodcastFolderSearchResult {
    func navigateTo() {
        switch kind {
        case .folder:
            NavigationManager.shared.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: DataManager.shared.findFolder(uuid: uuid) as Any])
        case .podcast:
            NavigationManager.shared.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: self])
        }
    }
}
