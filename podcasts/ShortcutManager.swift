import PocketCastsDataModel
import UIKit
import Combine

class ShortcutManager: CustomObserver {

    private var cancelable: Cancellable?

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

        let mergedMany = notifications
            .map { NotificationCenter.default.publisher(for: $0) }
            .reduce(Empty<Notification, Never>().eraseToAnyPublisher()) { acc, pub in
                acc.merge(with: pub).eraseToAnyPublisher()
            }
            .debounce(for: .seconds(3), scheduler: RunLoop.main)

        cancelable = mergedMany.sink { [weak self] _ in
            self?.shortcutsRequireUpdate()
        }

        shortcutsRequireUpdate()
    }

    func stopListeningForShortcutChanges() {
        cancelable?.cancel()
        cancelable = nil
    }

    @objc private func shortcutsRequireUpdate() {
        DispatchQueue.global().async { [weak self] () in
            guard let strongSelf = self else { return }

            strongSelf.updateShortcuts()
        }
    }

    private func updateShortcuts() {
        var shortcutItems = [UIMutableApplicationShortcutItem]()

        // top playlist
        if let topPlaylist = DataManager.sharedManager.allPlaylists(includeDeleted: false).first, let iconName = topPlaylist.iconImageName() {
            shortcutItems.append(
                UIMutableApplicationShortcutItem(
                    type: "au.com.shiftyjelly.podcasts",
                    localizedTitle: topPlaylist.playlistName,
                    localizedSubtitle: "\(DataManager.sharedManager.episodeCount(for: topPlaylist, episodeUuidToAdd: topPlaylist.episodeUuidToAddToQueries())) items",
                    icon: UIApplicationShortcutIcon(templateImageName: iconName),
                    userInfo: ["url": "pktc://shortcuts/filter/\(topPlaylist.uuid)" as NSSecureCoding]
                )
            )
        }

        if let currentEpisode = PlaybackManager.shared.currentEpisode() {
            // add a play/pause shortcut
            if PlaybackManager.shared.playing() {
                shortcutItems.append(
                    UIMutableApplicationShortcutItem(
                        type: "au.com.shiftyjelly.podcasts",
                        localizedTitle: L10n.pause,
                        localizedSubtitle: currentEpisode.displayableTitle(),
                        icon: UIApplicationShortcutIcon(type: .pause),
                        userInfo: ["url": "pktc://shortcuts/pause" as NSSecureCoding]
                    )
                )
            } else {
                shortcutItems.append(
                    UIMutableApplicationShortcutItem(
                        type: "au.com.shiftyjelly.podcasts",
                        localizedTitle: L10n.play,
                        localizedSubtitle: currentEpisode.displayableTitle(),
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
