import CoreServices
import Foundation
import JLRoutes
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        appDelegate()?.handleShortcutItem(shortcutItem)
    }

    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        if let urlString = shortcutItem.userInfo?["url"] as? String, let url = URL(string: urlString) {
            JLRoutes.routeURL(url)
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let progressViewController = SceneHelper.rootViewController() else { return false }
        return handleOpenUrl(url: url, rootViewController: progressViewController)
    }

    func handleOpenUrl(url: URL, rootViewController: UIViewController) -> Bool {
        if url.isFileURL {
            guard let type = UTType(filenameExtension: url.pathExtension) else { return false }

            let supportedTypes: [UTType] = [.xml, UTType("public.opml"), UTType("unofficial.opml")].compactMap { $0 }

            let isSupported = supportedTypes.contains { supportedType in
                type.conforms(to: supportedType)
            }

            if isSupported {
                progressDialog = ShiftyLoadingAlert(title: L10n.opmlImporting)
                rootViewController.dismiss(animated: false, completion: nil)
                progressDialog?.showAlert(rootViewController, hasProgress: false, completion: { [weak self] in
                    if let progressDialog = self?.progressDialog {
                        PodcastManager.shared.importPodcastsFromOpml(url, progressWindow: progressDialog)
                    }
                })
            } else if type.conforms(to: .audio) || type.conforms(to: .movie) {
                NavigationManager.sharedManager.navigateTo(NavigationManager.uploadedPageKey, data: [NavigationManager.uploadFileKey: url])
            }
        } else {
            // check to see what the scheme is we support itpc, http, feed & our own pktc
            if let scheme = url.scheme, scheme == "pktc" {
                JLRoutes.routeURL(url)
            }
        }
        return true
    }

    func setupRoutes() {
        // 3D touch shortcuts
        JLRoutes.global().addRoute("/shortcuts/:shortcut") { [weak self] parameters -> Bool in
            guard let strongSelf = self, let shortcut = parameters["shortcut"] as? String else { return false }

            if shortcut == "pause" {
                AnalyticsPlaybackHelper.shared.currentSource = .appIconMenu
                PlaybackManager.shared.pause()
                strongSelf.openPlayerWhenReadyFromExternalEvent()
                AnalyticsHelper.forceTouchPause()
            } else if shortcut == "play" {
                AnalyticsPlaybackHelper.shared.currentSource = .appIconMenu
                PlaybackManager.shared.play()
                strongSelf.openPlayerWhenReadyFromExternalEvent()
                AnalyticsHelper.forceTouchPlay()
            } else if shortcut == "markAsPlayed" {
                if let episode = PlaybackManager.shared.currentEpisode() {
                    AnalyticsEpisodeHelper.shared.currentSource = .appIconMenu
                    EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
                    AnalyticsHelper.forceTouchMarkPlayed()
                }
            } else if shortcut == "discover" {
                NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey, data: nil)
                AnalyticsHelper.forceTouchDiscover()
            }

            return true
        }

        // open a filter from a shortcut
        JLRoutes.global().addRoute("/shortcuts/filter/:filterId") { parameters -> Bool in
            guard let filterId = parameters["filterId"] as? String, let filter = DataManager.sharedManager.findFilter(uuid: filterId) else { return false }

            NavigationManager.sharedManager.navigateTo(NavigationManager.filterPageKey, data: [NavigationManager.filterUuidKey: filter.uuid])
            AnalyticsHelper.forceTouchTopFilter()

            return true
        }

        // open a podcast from a shortcut
        JLRoutes.global().addRoute("/shortcuts/podcast/:podcastUuid") { parameters -> Bool in
            guard let podcastUuid = parameters["podcastUuid"] as? String, let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid) else { return false }

            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
            AnalyticsHelper.forceTouchPodcast()

            return true
        }

        // share list page opened
        JLRoutes.global().addRoute("/sharelist/*") { parameters -> Bool in
            guard let pathComponents = parameters[JLRouteWildcardComponentsKey] as? [String] else { return false }

            let sharePath = pathComponents.joined(separator: "/")

            let jsonFileLocation = "http://\(sharePath).json"
            let listController = IncomingShareListViewController(jsonLocation: jsonFileLocation)
            let navController = SJUIUtils.popupNavController(for: listController)

            SceneHelper.rootViewController()?.present(navController, animated: true, completion: nil)

            return true
        }

        // URL schemes for open, play, pause
        JLRoutes.global().addRoute("/open") { _ -> Bool in
            true
        }
        JLRoutes.global().addRoute("/play") { _ -> Bool in
            PlaybackManager.shared.play()

            return true
        }
        JLRoutes.global().addRoute("/pause") { _ -> Bool in
            PlaybackManager.shared.pause()

            return true
        }

        // Open to discover
        JLRoutes.global().addRoute("/discover") { _ -> Bool in
            NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey, data: nil)
            return true
        }
        // developer features:
        JLRoutes.global().addRoute("/resetalltours") { _ -> Bool in
            Settings.setWhatsNewLastAcknowledged(0)

            return true
        }

        // Support for subscribing to a feed URL
        JLRoutes.global().addRoute("/subscribe/*") { [weak self] parameters -> Bool in
            guard let strongSelf = self, let controller = SceneHelper.rootViewController(), let subscribeUrl = (parameters[JLRouteURLKey] as? URL)?.absoluteString else { return false }

            let prefix = "pktc://subscribe/"
            if prefix.count >= subscribeUrl.count { return true } // this request is missing a URL

            let feedUrl = subscribeUrl.replacingOccurrences(of: prefix, with: "")
            let searchTerm = "http://\(feedUrl)"

            strongSelf.progressDialog = ShiftyLoadingAlert(title: L10n.podcastLoading)
            controller.dismiss(animated: false, completion: nil)
            strongSelf.progressDialog?.showAlert(controller, hasProgress: false, completion: {
                MainServerHandler.shared.podcastSearch(searchTerm: searchTerm) { response in
                    guard let uuid = response?.result?.podcast?.uuid else {
                        DispatchQueue.main.async {
                            self?.hideProgressDialog()

                            SJUIUtils.showAlert(title: L10n.error, message: L10n.errorGeneralPodcastNotFound, from: SceneHelper.rootViewController())
                        }

                        return
                    }
                    ServerPodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: false) { success in
                        DispatchQueue.main.async {
                            self?.hideProgressDialog()

                            if success {
                                NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: uuid])
                            } else {
                                SJUIUtils.showAlert(title: L10n.error, message: L10n.errorGeneralPodcastNotFound, from: SceneHelper.rootViewController())
                            }
                        }
                    }
                }
            })

            return true
        }

        // Today Centre Widget thingy
        JLRoutes.global().addRoute("/widget/*") { [weak self] parameters -> Bool in
            guard let strongSelf = self, let pathComponents = parameters[JLRouteWildcardComponentsKey] as? [String], let episodeUuid = pathComponents[safe: 0] else { return false }

            guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else { return true }

            strongSelf.openPlayerWhenReadyFromExternalEvent()

            if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
                if !PlaybackManager.shared.playing() {
                    PlaybackManager.shared.play()
                }
            } else {
                PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
            }

            return true
        }

        // Home screen Widget
        JLRoutes.global().addRoute("/widget-episode/*") { [weak self] parameters -> Bool in
            guard let strongSelf = self, let pathComponents = parameters[JLRouteWildcardComponentsKey] as? [String], let episodeUuid = pathComponents[safe: 0] else { return false }

            guard let baseEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else { return true }

            if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: baseEpisode.uuid) {
                strongSelf.openPlayerWhenReadyFromExternalEvent()
            } else {
                if let episode = baseEpisode as? Episode {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.episodePageKey, data: [NavigationManager.episodeUuidKey: episode.uuid])
                } else if baseEpisode is UserEpisode {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.filesPageKey, data: nil)
                }
            }
            return true
        }

        JLRoutes.global().addRoute("/last_opened/*")

        JLRoutes.global().addRoute("/show_player") { [weak self] _ -> Bool in
            self?.openPlayerWhenReadyFromExternalEvent()
            return true
        }

        // Sonos App Link
        JLRoutes.global().addRoute("/applink/sonos/*") { [weak self] parameters -> Bool in
            guard let strongSelf = self, let originalUrl = parameters[JLRouteURLKey] as? URL else { return false }

            let redirectUri = originalUrl.absoluteString.replacingOccurrences(of: "pktc://applink/sonos/", with: "")

            if let modalController = strongSelf.modalController {
                modalController.dismiss(animated: false, completion: nil)
            }

            let sonosController = SonosLinkController()
            sonosController.callbackUri = redirectUri
            let navController = SJUIUtils.navController(for: sonosController)
            strongSelf.modalController = navController
            SceneHelper.rootViewController()?.present(navController, animated: true, completion: nil)

            return true
        }

        JLRoutes.global().addRoute("social/share/:showOrPrivate/:sharingId") { [weak self] parameters -> Bool in
            guard let strongSelf = self, let folder = parameters["showOrPrivate"] as? String, let sharingId = parameters["sharingId"] as? String, let controller = SceneHelper.rootViewController() else { return false }

            FileLog.shared.addMessage("Opening share link, path: \(folder)/\(sharingId)")
            strongSelf.openSharePath("social/share/\(folder)/\(sharingId)", controller: controller, onErrorOpen: nil)
            return true
        }

        // Promotion Codes:
        JLRoutes.global().addRoute("/redeem/promo/*") { [weak self] parameters -> Bool in
            guard self != nil else { return false }
            var promoCode: String?
            if let pathComponents = parameters[JLRouteWildcardComponentsKey] as? [String], pathComponents.count > 0 {
                promoCode = pathComponents[0]
            }

            NavigationManager.sharedManager.navigateTo(NavigationManager.showPromotionPageKey, data: [NavigationManager.promotionInfoKey: promoCode as Any])
            return true
        }

        // Supporter Podcasts
        JLRoutes.global().addRoute("/premium/podcast/*") { [weak self] parameters -> Bool in
            guard self != nil else { return false }

            if let pathComponents = parameters[JLRouteWildcardComponentsKey] as? [String], pathComponents.count > 0, let podcastTitle = parameters["title"] as? String {
                let uuid = pathComponents[0]

                if SyncManager.isUserLoggedIn() {
                    RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
                    ApiServerHandler.shared.retrieveSubscriptionStatus()
                    var bundleUuid: String?
                    if let bundle = SubscriptionHelper.bundleSubscriptionForPodcast(podcastUuid: uuid) {
                        bundleUuid = bundle.bundleUuid
                    }
                    NavigationManager.sharedManager.navigateTo(NavigationManager.supporterBundlePageKey, data: [NavigationManager.supporterBundleUuid: bundleUuid as Any])
                } else {
                    var podcastInfo = PodcastInfo()
                    podcastInfo.uuid = uuid
                    podcastInfo.title = podcastTitle

                    NavigationManager.sharedManager.navigateTo(NavigationManager.supporterSignInKey, data: [NavigationManager.supporterPodcastInfo: podcastInfo])
                }
            }
            return true
        }

        JLRoutes.global().addRoute("/premium/supporter-contributions/*") { [weak self] parameters -> Bool in
            guard self != nil else { return false }
            if let pathComponents = parameters[JLRouteWildcardComponentsKey] as? [String], pathComponents.count > 0 {
                let uuid = pathComponents[0]

                if SyncManager.isUserLoggedIn() {
                    RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
                    ApiServerHandler.shared.retrieveSubscriptionStatus()
                    NavigationManager.sharedManager.navigateTo(NavigationManager.supporterBundlePageKey, data: [NavigationManager.supporterBundleUuid: uuid])
                } else {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.supporterSignInKey, data: [NavigationManager.supporterBundleUuid: uuid])
                }
            }
            return true
        }

        JLRoutes.global().addRoute("/upnext/*") { [weak self] paramDict -> Bool in
            var source: UpNextViewSource = .unknown

            if let sourceString = paramDict["source"] as? String {
                source = UpNextViewSource(rawValue: sourceString) ?? .unknown
            }

            self?.miniPlayer()?.showUpNext(from: source)

            return true
        }

        // Support - send IAP purchase receipt to server:
        JLRoutes.global().addRoute("/support/sendreceipt/*") { [weak self] _ -> Bool in
            guard self != nil else { return false }

            ApiServerHandler.shared.sendPurchaseReceipt(completion: { success in
                if success {
                    FileLog.shared.addMessage("AppDelegate successfully validated receipt")
                } else {
                    FileLog.shared.addMessage("AppDelegate failed to validate receipt")
                }
            })
            return true
        }

        // Import OMPL extension
        JLRoutes.global().addRoute("/import-file/*") { [weak self] parameters -> Bool in
            guard let self,
                  let rootViewController = SceneHelper.rootViewController(),
                  let originalUrl = parameters[JLRouteURLKey] as? URL else { return false }

            let fileURLString = originalUrl.absoluteString.replacingOccurrences(of: "pktc://import-file/", with: "")

            guard let fileURL = URL(string: fileURLString) else {
                return true
            }

            return self.handleOpenUrl(url: fileURL, rootViewController: rootViewController)
        }
    }

    func openSharePath(_ path: String, controller: UIViewController, onErrorOpen: URL?) {
        progressDialog = ShiftyLoadingAlert(title: L10n.sharedItemLoading)
        controller.dismiss(animated: false, completion: nil)

        progressDialog?.showAlert(controller, hasProgress: false) {
            // URLs that are already in the format https://pca.st/podcast/da3271a0-69e7-0132-d9fd-5f4c86fd3263 (or /private/) have the podcast UUID in them already so no need to ask the refresh server for it
            if path.contains("/podcast/") || path.contains("/private/") {
                if let lastSlashIndex = path.lastIndex(of: "/") {
                    let startIndex = path.index(lastSlashIndex, offsetBy: 1)
                    let uuid = path.suffix(from: startIndex)
                    let podcastHeader = PodcastHeader(uuid: String(uuid))
                    DispatchQueue.main.async {
                        self.hideProgressDialog()
                        NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcastHeader])
                    }

                    return
                }
            }

            PodcastManager.shared.importSharedItemFromUrl(path) { item in
                guard let item = item else {
                    self.hideProgressDialog()
                    FileLog.shared.addMessage("Unable to load shared item \(path)")
                    if let onErrorOpen = onErrorOpen {
                        UIApplication.shared.open(onErrorOpen, options: [:], completionHandler: nil)
                    }

                    return
                }

                if item.isPodcastOnly() {
                    guard let podcastHeader = item.podcastHeader else {
                        self.hideProgressDialog()

                        return
                    }

                    DispatchQueue.main.async {
                        self.hideProgressDialog()
                        NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcastHeader])
                    }
                } else if let episodeUuid = item.episodeHeader?.uuid, let podcastUuid = item.podcastHeader?.uuid {
                    self.loadAndShowEpisode(episodeUuid: episodeUuid, podcastUuid: podcastUuid)
                }
            }
        }
    }

    private func loadAndShowEpisode(episodeUuid: String, podcastUuid: String) {
        if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
            // if we're subscribed to the podcast, we'll likely have this episode, just open it
            if podcast.isSubscribed() {
                openEpisode(episodeUuid, from: podcast)
            } else { // if we're not subscribed, than it's possible our local copy is out of date, so we'll need to update it first
                ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast) { _ in
                    self.openEpisode(episodeUuid, from: podcast)
                }
            }

            return
        }

        ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUuid, subscribe: false, completion: { success in
            if success, let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
                self.openEpisode(episodeUuid, from: podcast)
            } else {
                DispatchQueue.main.async {
                    self.hideProgressDialog()
                    SJUIUtils.showAlert(title: L10n.podcastShareErrorTitle, message: L10n.podcastShareErrorMsg, from: SceneHelper.rootViewController())
                }
            }
        })
    }
}
