import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SwiftUI

class FolderModel: ObservableObject {
    @Published var folderUuid: String?
    @Published var selectedPodcastUuids: [String] = [] {
        didSet {
            guard let folderUuid = folderUuid, saveOnChange else { return }

            updateFoldersBasedOnSelection()

            DataManager.sharedManager.bulkSetFolderUuid(folderUuid: folderUuid, podcastUuids: selectedPodcastUuids)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folderUuid)
        }
    }

    @Published var name: String = "" {
        didSet {
            guard let folderUuid = folderUuid, saveOnChange else { return }

            if let folder = DataManager.sharedManager.findFolder(uuid: folderUuid) {
                folder.name = nameForFolder()
                folder.syncModified = TimeFormatter.currentUTCTimeInMillis()
                DataManager.sharedManager.save(folder: folder)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folderUuid)
                didChangeName = true
            }
        }
    }

    @Published var colorInt: Int = 0 {
        didSet {
            color = color(for: colorInt)

            guard let folderUuid = folderUuid, saveOnChange else { return }

            DataManager.sharedManager.updateFolderColor(folderUuid: folderUuid, color: Int32(colorInt), syncModified: TimeFormatter.currentUTCTimeInMillis())
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folderUuid)

            didChangeColor = true
        }
    }

    @Published var color: Color = .red

    var didChangeName = false

    var didChangeColor = false

    private let maximumAllowedCharactersForName = 100

    private let saveOnChange: Bool

    init(saveOnChange: Bool = false) {
        self.saveOnChange = saveOnChange
    }

    func color(for id: Int) -> Color {
        AppTheme.folderColor(colorInt: Int32(id)).color
    }

    func createFolder() -> String {
        // create and save the folder
        let folder = Folder()
        folder.name = nameForFolder()
        folder.color = Int32(colorInt)
        folder.addedDate = Date()
        folder.syncModified = TimeFormatter.currentUTCTimeInMillis()
        folder.sortOrder = ServerPodcastManager.shared.lowestSortOrderForHomeGrid() - 1

        // the sort type for newly created folders defaults to the same thing the home grid is set to
        folder.sortType = Int32(Settings.homeFolderSortOrder().old.rawValue)
        DataManager.sharedManager.save(folder: folder)

        // if needed update other folders we might have moved podcasts out of
        updateFoldersBasedOnSelection()

        // update all the podcasts in the folder to move them into it
        DataManager.sharedManager.bulkSetFolderUuid(folderUuid: folder.uuid, podcastUuids: selectedPodcastUuids)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folder.uuid)

        return folder.uuid
    }

    func deleteFolder() {
        guard let folderUuid = folderUuid else { return }

        DataManager.sharedManager.delete(folderUuid: folderUuid, markAsDeleted: SyncManager.isUserLoggedIn())
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderDeleted, object: folderUuid)
    }

    func nameForFolder() -> String {
        if name.trim().isEmpty {
            return L10n.folderNew
        }

        return name.trim()
    }

    func validateFolderName(_ value: String) {
        if value.count > maximumAllowedCharactersForName {
            name = String(value.prefix(maximumAllowedCharactersForName))
        }
    }

    private func updateFoldersBasedOnSelection() {
        var foldersChanged: Set<String> = []
        if let folderUuid = folderUuid { foldersChanged.insert(folderUuid) }

        // look for other folders that our selected podcasts may have come from, to update their syncModified dates
        for uuid in selectedPodcastUuids {
            guard let podcast = DataManager.sharedManager.findPodcast(uuid: uuid), let previousFolderUuid = podcast.folderUuid else { continue }

            foldersChanged.insert(previousFolderUuid)
        }

        DataManager.sharedManager.bulkSetSyncModified(TimeFormatter.currentUTCTimeInMillis(), onFolders: Array(foldersChanged))
    }
}
