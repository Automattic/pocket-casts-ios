import PocketCastsDataModel
import UIKit

class ShortcutManager: CustomObserver {
    func listenForShortcutChanges() {
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(shortcutsRequireUpdate))
        addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(shortcutsRequireUpdate))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(shortcutsRequireUpdate))
        addCustomObserver(Constants.Notifications.filterChanged, selector: #selector(shortcutsRequireUpdate))
        addCustomObserver(Constants.Notifications.podcastAdded, selector: #selector(shortcutsRequireUpdate))
        
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(shortcutsRequireUpdate))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(shortcutsRequireUpdate))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(shortcutsRequireUpdate))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(shortcutsRequireUpdate))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(shortcutsRequireUpdate))
        
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
                        localizedTitle: L10n.Localizable.pause,
                        localizedSubtitle: currentEpisode.displayableTitle(),
                        icon: UIApplicationShortcutIcon(type: .pause),
                        userInfo: ["url": "pktc://shortcuts/pause" as NSSecureCoding]
                    )
                )
            }
            else {
                shortcutItems.append(
                    UIMutableApplicationShortcutItem(
                        type: "au.com.shiftyjelly.podcasts",
                        localizedTitle: L10n.Localizable.play,
                        localizedSubtitle: currentEpisode.displayableTitle(),
                        icon: UIApplicationShortcutIcon(type: .play),
                        userInfo: ["url": "pktc://shortcuts/play" as NSSecureCoding]
                    )
                )
            }
        }
        else {
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
