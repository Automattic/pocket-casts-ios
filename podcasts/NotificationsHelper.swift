
import PocketCastsDataModel
import PocketCastsServer
import UIKit
import UserNotifications
import PocketCastsUtils

class NotificationsHelper: NSObject, UNUserNotificationCenterDelegate {
    private let downloadEpisodeActionId = "SJEpDownload"
    private let playNowActionid = "SJPlayNow"
    private let addToQueueFirstActionId = "SJEpAddQueueFirst"
    private let addToQueueLastActionId = "SJEpAddQueueLast"
    private let archiveActionId = "SJEpArchive"

    @objc static let shared = NotificationsHelper()

    enum NotificationsCategory: String {
        case deepLink = "DEEP_LINK"
        case episodes = "ep"
        case podcasts = "po"
    }

    func checkNotificationsDenied(completion: @escaping (Bool) -> ()) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .denied)
        }
    }

    @objc func pushEnabled() -> Bool {
        if FeatureFlag.newSettingsStorage.enabled {
            SettingsStore.appSettings.notifications
        } else {
            UserDefaults.standard.bool(forKey: Constants.UserDefaults.pushEnabled)
        }
    }

    func enablePush() {
        if pushEnabled() { return } // already enabled

        if FeatureFlag.newSettingsStorage.enabled {
            SettingsStore.appSettings.notifications = true
        }
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.pushEnabled)
    }

    func disablePush() {
        if FeatureFlag.newSettingsStorage.enabled {
            SettingsStore.appSettings.notifications = false
        }
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.pushEnabled)
    }

    /// Calls registration APIs if push is enabled
    /// - Parameter checkToken: Whether to check the token before registering. This would be `false` on app launch but could be checked while app is running to avoid extra work.
    func register(checkToken: Bool) {
        guard pushEnabled(),
              checkToken == false || ServerSettings.pushToken() == nil
        else { return }
        registerForPushNotifications()
    }

    func registerForPushNotifications(completion: ((Bool) -> ())? = nil) {
        let downloadAction = UNNotificationAction(identifier: downloadEpisodeActionId, title: L10n.download, options: [])
        let playNowAction = UNNotificationAction(identifier: playNowActionid, title: L10n.notificationsPlayNow, options: [])
        let addQueueFirstAction = UNNotificationAction(identifier: addToQueueFirstActionId, title: L10n.playNext, options: [])
        let addQueueLastAction = UNNotificationAction(identifier: addToQueueLastActionId, title: L10n.playLast, options: [])
        let archiveAction = UNNotificationAction(identifier: archiveActionId, title: L10n.archive, options: [])

        let episodeCategory = UNNotificationCategory(identifier: NotificationsCategory.episodes.rawValue, actions: [downloadAction, playNowAction, addQueueFirstAction, addQueueLastAction, archiveAction], intentIdentifiers: [], options: [])

        // multiple podcast episode actions
        let podcastCategory = UNNotificationCategory(identifier: NotificationsCategory.podcasts.rawValue, actions: [], intentIdentifiers: [], options: [])

        let deepLinkCategory = UNNotificationCategory(identifier: NotificationsCategory.deepLink.rawValue, actions: [], intentIdentifiers: [], options: [])

        // register actions
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.setNotificationCategories([episodeCategory, podcastCategory, deepLinkCategory])

        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                DispatchQueue.main.async {
                    completion?(settings.authorizationStatus != .denied)
                    UIApplication.shared.registerForRemoteNotifications()
                }
                return
            }

            notificationCenter.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { granted, _ in
                if granted {
                    Analytics.track(.notificationsOptInAllowed)
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    Analytics.track(.notificationsOptInDenied)
                }
                DispatchQueue.main.async {
                    completion?(granted)
                }
            })

            Analytics.track(.notificationsOptInShown)
        }
    }

    // called when the user taps a notification action, or just the notification itself
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        FileLog.shared.addMessage("[Notifications] push notification received with category: \(response.notification.request.content.categoryIdentifier)")
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        let category = NotificationsCategory(rawValue: categoryIdentifier)

        var properties: [String: Any] = ["category": categoryIdentifier]
        let identifier = response.notification.request.identifier
        if let type = NotificationType(rawValue: identifier) {
            properties["type"] = type.rawValue
            NotificationsCoordinator.shared.markNotification(type)
        }
        Analytics.track(.notificationOpened, properties: properties)

        switch category {
        case .episodes, .podcasts, .none:
            handleEpisodeNotification(response: response, completionHandler: completionHandler)
        case .deepLink:
            handleDeepLinkNotification(response: response, completionHandler: completionHandler)
        }
    }

    private func handleEpisodeNotification(response: UNNotificationResponse, completionHandler: @escaping () -> Void) {

        guard let episodeUuid = response.notification.request.content.userInfo["eu"] as? String, episodeUuid.count > 0 else {
            completionHandler()
            return
        }

        if downloadEpisodeActionId == response.actionIdentifier {
            AnalyticsHelper.downloadFromNotification()
            findEpisode(episodeUuid: episodeUuid) { episode in
                if let episode = episode {
                    DownloadManager.shared.addToQueue(episodeUuid: episode.uuid)
                }

                completionHandler()
            }
        } else if addToQueueFirstActionId == response.actionIdentifier || addToQueueLastActionId == response.actionIdentifier {
            let playFirst = addToQueueFirstActionId == response.actionIdentifier
            AnalyticsHelper.addToUpNextFromNotification(playFirst: playFirst)

            findEpisode(episodeUuid: episodeUuid) { episode in
                if let episode = episode {
                    PlaybackManager.shared.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: playFirst, userInitiated: true)
                }

                completionHandler()
            }
        } else if playNowActionid == response.actionIdentifier {
            AnalyticsHelper.playNowFromNotification()
            findEpisode(episodeUuid: episodeUuid) { episode in
                if let episode = episode {
                    PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
                }

                completionHandler()
            }
        } else if archiveActionId == response.actionIdentifier {
            AnalyticsHelper.archiveFromNotification()
            findEpisode(episodeUuid: episodeUuid) { episode in
                if let episode = episode as? Episode {
                    EpisodeManager.archiveEpisode(episode: episode, fireNotification: false)
                }

                completionHandler()
            }
        } else {
            // none of the actions where 3D Touched, the user just wants to open this episode if there is one
            findEpisode(episodeUuid: episodeUuid) { [weak self] episode in
                guard let self = self else { return }

                if let episode = episode as? Episode, let podcast = DataManager.sharedManager.findPodcast(uuid: episode.podcastUuid) {
                    self.appDelegate()?.openEpisode(episode.uuid, from: podcast)
                } else if let podcastUuid = response.notification.request.content.userInfo["podcast_uuid"] as? String, let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid) {
                    DispatchQueue.main.async {
                        NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
                    }
                }

                completionHandler()
            }
        }
    }

    // Called when a notification is delivered to a foreground app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    private func findEpisode(episodeUuid: String, performing action: @escaping (BaseEpisode?) -> Void) {
        if let existingEpisode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) {
            action(existingEpisode)
        } else {
            RefreshManager.shared.refreshPodcasts(completion: { _ in
                if let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) {
                    DispatchQueue.main.async {
                        action(episode)
                    }
                } else {
                    DispatchQueue.main.async {
                        action(nil)
                    }
                }
            })
        }
    }

    func handleDeepLinkNotification(response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        guard let destinationURLString = response.notification.request.content.userInfo["destination_url"] as? String,
              let url = URL(string: destinationURLString)
        else {
            completionHandler()
            return
        }
        FileLog.shared.addMessage("[Notifications] push notification received with deep link to:\(destinationURLString)")
        let _ = UIApplication.shared.delegate?.application?(UIApplication.shared, open: url)
        completionHandler()
    }
}
