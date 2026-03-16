import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class FolderHelper {
    class func addFolderToDatabase(_ folder: FolderSyncInfo) {
        if let _ = DataManager.sharedManager.findFolder(uuid: folder.uuid) {
            FileLog.shared.addMessage("addFolderToDatabase: skipping, folder \(folder.name) (\(folder.uuid)) it already exists")
            return
        }

        FileLog.shared.addMessage("Adding folder \(folder.name) (\(folder.uuid))")
        let localFolder = Folder()
        localFolder.uuid = folder.uuid
        localFolder.name = folder.name
        localFolder.sortType = Int32(ServerConverter.convertToClientSortType(serverType: folder.sortType))
        localFolder.sortOrder = folder.sortOrder
        localFolder.color = folder.color
        localFolder.addedDate = folder.addedDate

        DataManager.sharedManager.save(folder: localFolder)
    }
}
