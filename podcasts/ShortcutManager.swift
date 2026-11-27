import PocketCastsDataModel
import PocketCastsUtils
import UIKit
import Combine

class ShortcutManager: CustomObserver {

    private var cancelable: Cancellable?
    private var backgroundCancelable: Cancellable?
    private var isUpdateNeeded = false

    func listenForShortcutChanges() {
        //Cleans up existing observers
        stopListeningForShortcutChanges()

        let notifications: [NSNotification.Name] = [Constants.Notifications.playbackStarted,
                                                    Constants.Notifications.playbackPaused,
                                                    Constants.Notifications.playbackEnded,
                                                    Constants.Notifications.playlistChanged,
                                                    Constants.Notifications.podcastAdded,
                                                    Constants.Notifications.episodePlayStatusChanged,
                                                    Constants.Notifications.episodeArchiveStatusChanged,
                                                    Constants.Notifications.episodeStarredChanged,
                                                    Constants.Notifications.episodeDownloadStatusChanged,
                                                    Constants.Notifications.manyEpisodesChanged]

        let mergedNotifications = notifications
            .map { NotificationCenter.default.publisher(for: $0) }
            .reduce(Empty<Notification, Never>().eraseToAnyPublisher()) { acc, pub in
                acc.merge(with: pub).eraseToAnyPublisher()
            }
            .debounce(for: .seconds(3), scheduler: RunLoop.main)

        cancelable = mergedNotifications.sink { [weak self] _ in
            self?.setNeedsUpdate()
        }

        backgroundCancelable = NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.updateIfNeeded()
            }

        isUpdateNeeded = true
    }

    func stopListeningForShortcutChanges() {
        cancelable?.cancel()
        cancelable = nil
        backgroundCancelable?.cancel()
        backgroundCancelable = nil
    }

    private func setNeedsUpdate() {
        isUpdateNeeded = true
        if UIApplication.shared.applicationState == .background {
            updateIfNeeded()
        }
    }

    private func updateIfNeeded() {
        guard isUpdateNeeded else { return }
        isUpdateNeeded = false

        let currentEpisodeTitle = PlaybackManager.shared.currentEpisode?.displayableTitle()
        let isPlaying = PlaybackManager.shared.isPlaying

        let application = UIApplication.shared
        var taskID = UIBackgroundTaskIdentifier.invalid
        taskID = application.beginBackgroundTask(withName: "UpdateShortcuts") {
            application.endBackgroundTask(taskID)
        }

        DispatchQueue.global().async { [weak self] in
            self?.updateShortcuts(currentEpisodeTitle: currentEpisodeTitle, isPlaying: isPlaying)
            DispatchQueue.main.async {
                application.endBackgroundTask(taskID)
            }
        }
    }

    private func updateShortcuts(currentEpisodeTitle: String?, isPlaying: Bool) {
        var shortcutItems = [UIMutableApplicationShortcutItem]()

        // top playlist
        if let topPlaylist = DataManager.shared.allPlaylists(includeDeleted: false).first, let iconName = topPlaylist.iconImageName() {
            shortcutItems.append(
                UIMutableApplicationShortcutItem(
                    type: "au.com.shiftyjelly.podcasts",
                    localizedTitle: topPlaylist.playlistName,
                    localizedSubtitle: "\(DataManager.shared.episodeCount(for: topPlaylist, episodeUuidToAdd: topPlaylist.episodeUuidToAddToQueries())) items",
                    icon: UIApplicationShortcutIcon(templateImageName: iconName),
                    userInfo: ["url": "pktc://shortcuts/filter/\(topPlaylist.uuid)" as NSSecureCoding]
                )
            )
        }

        if let currentEpisodeTitle {
            // add a play/pause shortcut
            if isPlaying {
                shortcutItems.append(
                    UIMutableApplicationShortcutItem(
                        type: "au.com.shiftyjelly.podcasts",
                        localizedTitle: L10n.pause,
                        localizedSubtitle: currentEpisodeTitle,
                        icon: UIApplicationShortcutIcon(type: .pause),
                        userInfo: ["url": "pktc://shortcuts/pause" as NSSecureCoding]
                    )
                )
            } else {
                shortcutItems.append(
                    UIMutableApplicationShortcutItem(
                        type: "au.com.shiftyjelly.podcasts",
                        localizedTitle: L10n.play,
                        localizedSubtitle: currentEpisodeTitle,
                        icon: UIApplicationShortcutIcon(type: .play),
                        userInfo: ["url": "pktc://shortcuts/play" as NSSecureCoding]
                    )
                )
            }
        } else {
            // discover
            shortcutItems.append(
                UIMutableApplicationShortcutItem(
                    type: "au.com.shiftyjelly.podcasts",
                    localizedTitle: "Find New Podcasts",
                    localizedSubtitle: nil,
                    icon: UIApplicationShortcutIcon(type: .search),
                    userInfo: ["url": "pktc://shortcuts/discover" as NSSecureCoding]
                )
            )
        }

        DispatchQueue.main.async {
            UIApplication.shared.shortcutItems = shortcutItems
        }
    }
}
