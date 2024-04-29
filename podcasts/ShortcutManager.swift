import PocketCastsDataModel
import UIKit
import Combine

class ShortcutManager: CustomObserver {
    private var cancellables = Set<AnyCancellable>()

    func listenForShortcutChanges() {

        let notificationNames = [
            Constants.Notifications.playbackStarted,
            Constants.Notifications.playbackPaused,
            Constants.Notifications.playbackEnded,
            Constants.Notifications.filterChanged,
            Constants.Notifications.podcastAdded,
            Constants.Notifications.episodePlayStatusChanged,
            Constants.Notifications.episodeArchiveStatusChanged,
            Constants.Notifications.episodeStarredChanged,
            Constants.Notifications.episodeDownloadStatusChanged,
            Constants.Notifications.manyEpisodesChanged
        ]

        let publishers = notificationNames.map {
            NotificationCenter.default.publisher(for: $0)
        }
        let mergedPublisher = Publishers.MergeMany(publishers)
        mergedPublisher.debounce(for: .seconds(1), scheduler: RunLoop.main).sink { [weak self] event in
            self?.shortcutsRequireUpdate()
        }.store(in: &cancellables)

        shortcutsRequireUpdate()
    }

    func stopListeningForShortcutChanges() {
        removeAllCustomObservers()
    }

    @objc private func shortcutsRequireUpdate() {
        DispatchQueue.global().async { [weak self] () in
            guard let strongSelf = self else { return }

            strongSelf.updateShortcuts()
        }
    }

    private func updateShortcuts() {
        var shortcutItems = [UIMutableApplicationShortcutItem]()

        // top filter
        if let topFilter = DataManager.sharedManager.allFilters(includeDeleted: false).first, let iconName = topFilter.iconImageName() {
            shortcutItems.append(
                UIMutableApplicationShortcutItem(
                    type: "au.com.shiftyjelly.podcasts",
                    localizedTitle: topFilter.playlistName,
                    localizedSubtitle: "\(DataManager.sharedManager.episodeCount(forFilter: topFilter, episodeUuidToAdd: topFilter.episodeUuidToAddToQueries())) items",
                    icon: UIApplicationShortcutIcon(templateImageName: iconName),
                    userInfo: ["url": "pktc://shortcuts/filter/\(topFilter.uuid)" as NSSecureCoding]
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
