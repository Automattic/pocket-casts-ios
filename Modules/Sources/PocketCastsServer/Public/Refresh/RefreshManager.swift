import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import UIKit
#if os(watchOS)
    import WatchKit
#endif

public class RefreshManager {
    public static let shared = RefreshManager()

    lazy var refreshQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    /// Runs Up Next syncs one at a time, apart from the refresh, so Up Next changes don't wait for a refresh to finish.
    lazy var upNextQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    /// The episode each podcast's next refresh should start after, kept while the sync ran but the refresh failed.
    private let pendingLastEpisodesLock = NSLock()

    #if !os(watchOS)
    /// The refresh of all podcasts that's running, which refreshes that aren't forced join.
    private let runningRefresh = RefreshCoalescer()
    #endif

    // the watch has less resources than a phone, so be a bit more aggressive about not refreshing constantly
    #if os(watchOS)
        private static let minTimeBetweenRefreshes = 1.minute
    #else
        private static let minTimeBetweenRefreshes = 15.seconds
    #endif

    public func syncUpNext() {
        if !SyncManager.isUserLoggedIn() { return }

        // if the user has an active subscription, there might be custom episodes in their Up Next, so grab those first
        let queue = FeatureFlag.refreshImprovements.enabled ? upNextQueue : refreshQueue
        if SubscriptionHelper.hasActiveSubscription() {
            queue.addOperation(RetrieveCustomFilesTask())
        }
        queue.addOperation(UpNextSyncTask())
    }


    /// Updates a podcast and all the associated information.
    ///
    /// Note that this will force all the episodes to be updated.
    /// - Parameter podcast: a `Podcast` object
    public func refresh(podcast: Podcast, from episodeUuid: String) {
        podcast.forceRefreshEpisodeFrom = episodeUuid
        refresh(podcasts: [podcast]) { _ in
            if SyncManager.isUserLoggedIn() {
                guard let episodes = ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: podcast.uuid) else { return }

                DataManager.shared.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
                podcast.forceRefreshEpisodeFrom = nil
            }
        }
    }

    public func refresh(podcast: Podcast, from episodeUuid: String) async {
        podcast.forceRefreshEpisodeFrom = episodeUuid
        await withCheckedContinuation { continuation in
            refresh(podcasts: [podcast]) { _ in
                if SyncManager.isUserLoggedIn() {
                    guard let episodes = ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: podcast.uuid) else { return }

                    DataManager.shared.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
                    podcast.forceRefreshEpisodeFrom = nil
                }
                continuation.resume()
            }
        }
    }

    public func refreshPodcasts(forceEvenIfRefreshedRecently: Bool = false) {
        #if !os(watchOS)
        var refreshID: UUID?
        if !forceEvenIfRefreshedRecently, FeatureFlag.refreshImprovements.enabled {
            guard let id = runningRefresh.begin(completion: nil) else {
                FileLog.shared.addMessage("Refresh - Joined the refresh that's already running")
                return
            }
            refreshID = id
        }
        #endif

        if !forceEvenIfRefreshedRecently {
            if let lastRefreshStartTime = ServerSettings.lastRefreshStartTime(), fabs(lastRefreshStartTime.timeIntervalSinceNow) < RefreshManager.minTimeBetweenRefreshes {
                // if it's been less than minTimeBetweenRefreshes since our last refresh, don't do another one. Effectively throttling user refreshes a little bit
                FileLog.shared.addMessage("Refresh - Throttled")
                #if !os(watchOS)
                if let refreshID {
                    runningRefresh.finish(id: refreshID, result: .noData)
                }
                #endif
                DispatchQueue.global().async {
                    Thread.sleep(forTimeInterval: 1.second)
                    ServerNotificationsHelper.shared.firePodcastsUpdated()
                    NotificationCenter.default.post(name: ServerNotifications.podcastRefreshThrottled, object: nil)
                }

                return
            }
        }

        #if os(watchOS)
        refresh(podcasts: DataManager.shared.allPodcasts(includeUnsubscribed: false))
        #else
        refresh(podcasts: DataManager.shared.allPodcasts(includeUnsubscribed: false)) { [weak self] result in
            if let refreshID {
                self?.runningRefresh.finish(id: refreshID, result: result)
            }
        }
        #endif
    }

    #if !os(watchOS)
    private func refresh(podcasts: [Podcast], completion: ((RefreshFetchResult) -> Void)? = nil) {
        UserDefaults.standard.set(Date(), forKey: ServerConstants.UserDefaults.lastRefreshStartTime)

        DispatchQueue.global().async { [weak self] in
            self?.performRefresh(podcasts: podcasts, completion: completion)
        }
    }

    private func performRefresh(podcasts: [Podcast], completion: ((RefreshFetchResult) -> Void)?) {
        guard FeatureFlag.syncBeforeRefresh.enabled, SyncManager.isUserLoggedIn() else {
            MainServerHandler.shared.refresh(podcasts: podcasts) { [weak self] refreshResponse in
                self?.processPodcastRefreshResponse(refreshResponse, completion: completion)
            }
            return
        }

        // The request captures each podcast's latest episode, so build it before the sync adds any
        let lastEpisodes = pendingLastEpisodes()
        let requests = MainServerHandler.shared.makeRefreshRequests(podcasts: podcasts, lastEpisodeOverrides: lastEpisodes)
        let requestedLastEpisodes = Dictionary(podcasts.map { ($0.uuid, lastEpisodes[$0.uuid] ?? $0.forceRefreshEpisodeFrom ?? $0.latestEpisodeUuid ?? "") }, uniquingKeysWith: { first, _ in first })

        let sync = SyncOperation()
        refreshQueue.addOperation(sync)

        MainServerHandler.shared.refresh(requests: requests) { [weak self] refreshResponse in
            guard let self else { return }

            if refreshResponse?.success() == true {
                self.removePendingLastEpisodes(for: Array(requestedLastEpisodes.keys))
            } else {
                // The sync may have added episodes newer than the ones this refresh was meant to fetch
                self.addPendingLastEpisodes(requestedLastEpisodes)
            }
            self.processPodcastRefreshResponse(refreshResponse, previousSync: sync, completion: completion)
        }
    }

    private func pendingLastEpisodes() -> [String: String] {
        pendingLastEpisodesLock.withLock {
            UserDefaults.standard.dictionary(forKey: ServerConstants.UserDefaults.refreshPendingLastEpisodes) as? [String: String] ?? [:]
        }
    }

    private func addPendingLastEpisodes(_ lastEpisodes: [String: String]) {
        pendingLastEpisodesLock.withLock {
            let pending = UserDefaults.standard.dictionary(forKey: ServerConstants.UserDefaults.refreshPendingLastEpisodes) as? [String: String] ?? [:]
            UserDefaults.standard.set(pending.merging(lastEpisodes) { existing, _ in existing }, forKey: ServerConstants.UserDefaults.refreshPendingLastEpisodes)
        }
    }

    private func removePendingLastEpisodes(for podcastUuids: [String]) {
        pendingLastEpisodesLock.withLock {
            guard var pending = UserDefaults.standard.dictionary(forKey: ServerConstants.UserDefaults.refreshPendingLastEpisodes) as? [String: String], !pending.isEmpty else { return }

            podcastUuids.forEach { pending[$0] = nil }
            UserDefaults.standard.set(pending, forKey: ServerConstants.UserDefaults.refreshPendingLastEpisodes)
        }
    }
    #endif

    #if os(watchOS)
    // Watch OS 10 has a very very very weird issue that happened after using Xcode 16:
    // if the refresh call uses a [weak self] the system kills the app.
    // I'm not entirely sure why that happens but removing the weak part fixes the issue.
    // We can safely remove this method once we remove support to watchOS 10.
    private func refresh(podcasts: [Podcast], completion: ((RefreshFetchResult) -> Void)? = nil) {
        UserDefaults.standard.set(Date(), forKey: ServerConstants.UserDefaults.lastRefreshStartTime)

        DispatchQueue.global().async { [self] in
            let watchOsMajorVersion = WKInterfaceDevice.current().systemVersion.split(separator: ".")[safe: 0]

            if watchOsMajorVersion == "10" {
                // Let's not use [weak self] so the app is not killed
                MainServerHandler.shared.refresh(podcasts: podcasts) { refreshResponse in
                    self.processPodcastRefreshResponse(refreshResponse, completion: completion)
                }

                return
            }

            MainServerHandler.shared.refresh(podcasts: podcasts) { [weak self] refreshResponse in
                guard let self else { return }

                self.processPodcastRefreshResponse(refreshResponse, completion: completion)
            }
        }
    }
    #endif

    public func refreshPodcasts(completion: @escaping (RefreshFetchResult) -> Void) {
        #if !os(watchOS)
        var refreshID: UUID?
        if FeatureFlag.refreshImprovements.enabled {
            guard let id = runningRefresh.begin(completion: completion) else {
                FileLog.shared.addMessage("Refresh - Joined the refresh that's already running")
                return
            }
            refreshID = id
        }
        #endif

        DispatchQueue.global().async { [weak self] in
            let podcasts = DataManager.shared.allPodcasts(includeUnsubscribed: false)
            #if os(watchOS)
            MainServerHandler.shared.refresh(podcasts: podcasts) { [weak self] refreshResponse in
                guard let self else { return }

                self.processPodcastRefreshResponse(refreshResponse, completion: completion)
            }
            #else
            self?.performRefresh(podcasts: podcasts) { [weak self] result in
                if let refreshID {
                    self?.runningRefresh.finish(id: refreshID, result: result)
                } else {
                    completion(result)
                }
            }
            #endif
        }
    }

    public func cancelAllRefreshes() {
        refreshQueue.cancelAllOperations()
        #if !os(watchOS)
        runningRefresh.cancel()
        #endif
    }

    private func processPodcastRefreshResponse(_ refreshResponse: PodcastRefreshResponse?, previousSync: SyncOperation? = nil, completion: ((RefreshFetchResult) -> Void)?) {
        guard let response = refreshResponse, response.success() else {
            FileLog.shared.addMessage("Podcast refresh failed with message: \(refreshResponse?.message ?? "none"). See previous log for more details.")
            ServerNotificationsHelper.shared.firePodcastRefreshFailed()
            if previousSync != nil {
                // report back once the sync that started with this refresh has finished
                refreshQueue.addOperation { completion?(.failed) }
            } else {
                completion?(.failed)
            }

            return
        }

        let refreshOperation = RefreshOperation(result: response.result ?? RefreshResult(), previousSync: previousSync, completionHandler: completion)
        refreshQueue.addOperation(refreshOperation)
    }
}
