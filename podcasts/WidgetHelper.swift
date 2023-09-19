
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WidgetKit

class WidgetHelper {
    static let shared = WidgetHelper()
    static let appGroupId = "group.au.com.shiftyjelly.pocketcasts"
    static let maxUpNextToPublish = 10
    static let maxFilterToPublish = 5
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.playbackStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.playbackEnded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.playbackTrackChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.playbackPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.currentlyPlayingEpisodeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.upNextQueueChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification), name: Constants.Notifications.upNextEpisodeRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilterChanged), name: Constants.Notifications.filterChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilterChanged), name: Constants.Notifications.podcastAdded, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func updateAllWidgets() {
        WidgetCenter.shared.getCurrentConfigurations { result in
            guard case .success = result, let widgets = try? result.get(), widgets.count > 0 else { return }

            if widgets.contains(where: { $0.kind == "Now_Playing_Widget" }) {
                self.publishAppIcon()
            }
            if widgets.contains(where: { $0.kind == "Up_Next_Widget" }), PlaybackManager.shared.currentEpisode() == nil, PlaybackManager.shared.queue.upNextCount() == 0 {
                self.publishTopFilterInfo()
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @objc func updateFromNotification() {
        updateSharedUpNext()
    }

    func updateSharedUpNext() {
        #if !os(watchOS)
            publishUpNextInfo()
            updateAllWidgets()
        #endif
    }

    func updateUpNextWidgets() {
        WidgetCenter.shared.getCurrentConfigurations { result in
            guard case .success = result else { return }
            WidgetCenter.shared.reloadTimelines(ofKind: "Up_Next_Widget")
        }
    }

    func updateWidgetAppIcon() {
        WidgetCenter.shared.getCurrentConfigurations { result in
            guard case .success = result, let widgets = try? result.get() else { return }
            if widgets.contains(where: { $0.kind == "Now_Playing_Widget" }) {
                self.publishAppIcon()
                WidgetCenter.shared.reloadTimelines(ofKind: "Now_Playing_Widget")
            }
        }
    }

    @objc func handleFilterChanged() {
        guard PlaybackManager.shared.currentEpisode() == nil else {
            return
        }
        updateSharedUpNext()
    }

    // MARK: - Up Next Widget

    private func publishUpNextInfo() {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId) else { return }

        let allUpNextPlaylistEpisodes = DataManager.sharedManager.allUpNextPlaylistEpisodes()
        var upNextItems = [CommonUpNextItem]()
        for (index, playlistEpisode) in allUpNextPlaylistEpisodes.enumerated() {
            if index > WidgetHelper.maxUpNextToPublish { break }

            if let episode = DataManager.sharedManager.findBaseEpisode(uuid: playlistEpisode.episodeUuid), let upNextItem = convertToWidgetItem(episode: episode) {
                upNextItems.append(upNextItem)
            }
        }

        do {
            let serializedItems = try JSONEncoder().encode(upNextItems)
            sharedDefaults.set(serializedItems, forKey: SharedConstants.GroupUserDefaults.upNextItems)
            sharedDefaults.set(max(allUpNextPlaylistEpisodes.count - 1, 0), forKey: SharedConstants.GroupUserDefaults.upNextItemsCount)
            sharedDefaults.removeObject(forKey: SharedConstants.GroupUserDefaults.topFilterItems)
            sharedDefaults.removeObject(forKey: SharedConstants.GroupUserDefaults.topFilterName)
            let playingStatus = PlaybackManager.shared.playing()
            sharedDefaults.set(playingStatus, forKey: SharedConstants.GroupUserDefaults.isPlaying)

            sharedDefaults.synchronize()
        } catch {
            FileLog.shared.addMessage("Unable to encode data for Up Next Widget: \(error.localizedDescription)")
        }
    }

    private func publishTopFilterInfo() {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId) else { return }

        var filterItems = [CommonUpNextItem]()
        var filterName: String?
        if let topFilter = DataManager.sharedManager.allFilters(includeDeleted: false).first {
            filterName = topFilter.playlistName
            let query = PlaylistHelper.queryFor(filter: topFilter, episodeUuidToAdd: topFilter.episodeUuidToAddToQueries(), limit: WidgetHelper.maxFilterToPublish)

            let loadedEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
            for (index, playlistEpisode) in loadedEpisodes.enumerated() {
                if index >= WidgetHelper.maxFilterToPublish { break }

                if let episode = DataManager.sharedManager.findBaseEpisode(uuid: playlistEpisode.uuid), let item = convertToWidgetItem(episode: episode) {
                    filterItems.append(item)
                }
            }
        }
        do {
            let serializedItems = try JSONEncoder().encode(filterItems)
            sharedDefaults.set(serializedItems, forKey: SharedConstants.GroupUserDefaults.topFilterItems)
            sharedDefaults.set(filterName, forKey: SharedConstants.GroupUserDefaults.topFilterName)
            sharedDefaults.set(false, forKey: SharedConstants.GroupUserDefaults.isPlaying)
            sharedDefaults.removeObject(forKey: SharedConstants.GroupUserDefaults.upNextItems)
            sharedDefaults.synchronize()
        } catch {
            FileLog.shared.addMessage("Unable to encode top filter data  Widget: \(error.localizedDescription)")
        }
    }

    private func convertToWidgetItem(episode: BaseEpisode) -> CommonUpNextItem? {
        let episodeTitle = episode.title ?? ""
        var duration = episode.duration
        var isPlaying = false
        let currentTime = PlaybackManager.shared.currentTime()

        if episode.uuid == PlaybackManager.shared.currentEpisode()?.uuid, currentTime.isFinite {
            duration = duration - currentTime
            isPlaying = PlaybackManager.shared.playing()
        }
        let podcastColor: UIColor = ColorManager.backgroundColorForPodcastUuid(episode.parentIdentifier())
        var imageUrl = ""

        if let episode = episode as? Episode {
            imageUrl = ServerHelper.image(podcastUuid: episode.parentIdentifier(), size: 340)
        } else if let userEpisode = episode as? UserEpisode {
            imageUrl = userEpisodeImageString(userEpisode)
        }

        return CommonUpNextItem(episodeUuid: episode.uuid, imageUrl: imageUrl, episodeTitle: episodeTitle, podcastName: episode.subTitle(), podcastColor: podcastColor.hexString(), duration: duration, isPlaying: isPlaying)
    }

    func publishAppIcon() {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId) else { return }
        let sharedAppIcon = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.appIcon) as? String
        DispatchQueue.main.async {
            let currentAppIcon = UIApplication.shared.alternateIconName

            if currentAppIcon != sharedAppIcon {
                sharedDefaults.set(currentAppIcon, forKey: SharedConstants.GroupUserDefaults.appIcon)
                sharedDefaults.synchronize()
            }
        }
    }

    func updateCustomImage(userEpisode: UserEpisode) {
        guard PlaybackManager.shared.inUpNext(episode: userEpisode), userEpisode.urlForImage().isFileURL, let sharedPath = sharedWidgetImagePathFor(userEpisode) else { return }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: sharedPath.path) {
            do {
                try fileManager.removeItem(atPath: sharedPath.path)
            } catch {}
        }
        updateSharedUpNext()
    }

    private func sharedWidgetImagePathFor(_ userEpisode: UserEpisode) -> URL? {
        let sharedDirectory = sharedWidgetImageDirectory()
        let fileName = "\(userEpisode.uuid).jpg"
        return sharedDirectory?.appendingPathComponent(fileName)
    }

    private func sharedWidgetImageDirectory() -> URL? {
        let fileManager = FileManager.default
        guard let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: WidgetHelper.appGroupId) else {
            return nil
        }
        return container.appendingPathComponent("widget_images")
    }

    private func userEpisodeImageString(_ userEpisode: UserEpisode) -> String {
        let imageUrl = userEpisode.urlForImage().absoluteString
        guard imageUrl.hasPrefix("file"), let path = URL(string: imageUrl), let sharedDirectory = sharedWidgetImageDirectory(), let sharedPath = sharedWidgetImagePathFor(userEpisode) else {
            return imageUrl
        }
        do {
            let fileManager = FileManager.default
            var isDir: ObjCBool = false
            if !fileManager.fileExists(atPath: sharedDirectory.path, isDirectory: &isDir) {
                try fileManager.createDirectory(at: sharedDirectory, withIntermediateDirectories: false, attributes: nil)
            }
            if !fileManager.fileExists(atPath: sharedPath.path),
               let customImage = UIImage(contentsOfFile: path.path), let downsized = customImage.resized(to: CGSize(width: 280, height: 280)) {
                try downsized.jpegData(compressionQuality: 1)?.write(to: sharedPath)
            }
            return sharedPath.absoluteString
        } catch let error as NSError {
            FileLog.shared.addMessage("Failed to copy custom file image to app group \(error.localizedDescription)")
        }
        return ""
    }

    func cleanupAppGroupImages() {
        guard let imageDirectory = sharedWidgetImageDirectory() else { return }

        let fileManager = FileManager.default

        // don't bother cleaning the folder if it hasn't been created
        guard fileManager.fileExists(atPath: imageDirectory.absoluteString) else { return }

        do {
            var upNextUuids = [String]()
            let upNextEpisodes = PlaybackManager.shared.allEpisodesInQueue(includeNowPlaying: true)
            if upNextEpisodes.count > 0 {
                let numUpNextUuids = max(0, min(WidgetHelper.maxUpNextToPublish, upNextEpisodes.count - 1))
                upNextUuids = upNextEpisodes[0 ... numUpNextUuids].map(\.uuid)
            }

            let fileURLs = try fileManager.contentsOfDirectory(at: imageDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                let uuid = file.lastPathComponent.replacingOccurrences(of: ".jpg", with: "")
                if !upNextUuids.contains(uuid) {
                    try fileManager.removeItem(atPath: file.path)
                }
            }
        } catch let error as NSError {
            FileLog.shared.addMessage("Failed to clean up custom images from app group: \(error.localizedDescription)")
        }
    }
}
