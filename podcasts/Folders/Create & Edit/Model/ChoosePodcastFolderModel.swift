import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SwiftUI

class ChoosePodcastFolderModel: ObservableObject {
    @Published var pickingForPodcastUuid: String
    @Published var availableFolders: [Folder] = []
    @Published var currentFolder: String

    private var rootFolder: Folder = {
        let folder = Folder()
        folder.uuid = "root"

        return folder
    }()

    /// `true` when a podcast moved to a new folder
    var didMoveToFolder = false

    /// `true` when a podcast was removed from a folder
    var didRemoveFromFolder = false

    init(pickingFor podcastUuid: String, currentFolder: String?) {
        pickingForPodcastUuid = podcastUuid

        self.currentFolder = currentFolder ?? rootFolder.uuid
    }

    func loadFolders() {
        var allFolders = DataManager.sharedManager.allFolders()
        allFolders.sort { folder1, folder2 in
            let title1 = nameForFolder(folder: folder1)
            let title2 = nameForFolder(folder: folder2)

            return PodcastSorter.titleSort(title1: title1, title2: title2)
        }
        allFolders.insert(rootFolder, at: 0)

        availableFolders = allFolders
    }

    func podcastCountForFolder(folder: Folder) -> Int {
        if folder.uuid == rootFolder.uuid {
            return DataManager.sharedManager.countOfPodcastsInRootFolder()
        }

        return DataManager.sharedManager.countOfPodcastsInFolder(folder: folder)
    }

    func colorForFolder(folder: Folder) -> Color? {
        guard folder.uuid != rootFolder.uuid else {
            return nil
        }

        return AppTheme.folderColor(colorInt: folder.color).color
    }

    func nameForFolder(folder: Folder) -> String {
        guard folder.uuid != rootFolder.uuid else { return L10n.folderNoFolder }

        return folder.name.isEmpty ? L10n.folderUnnamed : folder.name
    }

    func movePodcastToFolder(_ folder: Folder) {
        if folder.uuid != rootFolder.uuid {
            movePodcastTo(folder: folder)
        } else {
            removePodcastFromFolder()
        }
    }

    private func movePodcastTo(folder: Folder) {
        if currentFolder == folder.uuid { return } // already in this folder

        updateLastSync(folderUuid: currentFolder)
        let sortOrder = ServerPodcastManager.shared.highestSortOrderForFolder(folder) + 1
        DataManager.sharedManager.updatePodcastFolder(podcastUuid: pickingForPodcastUuid, to: folder.uuid, sortOrder: sortOrder)
        updateLastSync(folderUuid: folder.uuid)

        currentFolder = folder.uuid
        loadFolders()

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: currentFolder)

        didMoveToFolder = true
    }

    private func removePodcastFromFolder() {
        if currentFolder == rootFolder.uuid { return } // already in the root folder

        updateLastSync(folderUuid: currentFolder)
        let sortOrder = ServerPodcastManager.shared.highestSortOrderForHomeGrid() + 1
        DataManager.sharedManager.updatePodcastFolder(podcastUuid: pickingForPodcastUuid, to: nil, sortOrder: sortOrder)

        currentFolder = rootFolder.uuid
        loadFolders()

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged)

        didRemoveFromFolder = true
    }

    private func updateLastSync(folderUuid: String) {
        if folderUuid == rootFolder.uuid { return }

        DataManager.sharedManager.updateFolderSyncModified(folderUuid: folderUuid, syncModified: TimeFormatter.currentUTCTimeInMillis())
    }
}
