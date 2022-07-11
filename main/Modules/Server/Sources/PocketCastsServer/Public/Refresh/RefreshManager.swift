import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

public class RefreshManager {
    public static let shared = RefreshManager()
    
    lazy var refreshQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
    // the watch has less resources than a phone, so be a bit more agressive about not refreshing constantly
    #if os(watchOS)
        private static let minTimeBetweenRefreshes = 1.minute
    #else
        private static let minTimeBetweenRefreshes = 15.seconds
    #endif
    
    public func syncUpNext() {
        if !SyncManager.isUserLoggedIn() { return }
        
        // if the user has an active subscription, there might be custom episodes in their Up Next, so grab those first
        if SubscriptionHelper.hasActiveSubscription() {
            refreshQueue.addOperation(RetrieveCustomFilesTask())
        }
        refreshQueue.addOperation(UpNextSyncTask())
    }
    
    public func refreshPodcasts(forceEvenIfRefreshedRecently: Bool = false) {
        if !forceEvenIfRefreshedRecently {
            if let lastRefreshStartTime = ServerSettings.lastRefreshStartTime(), fabs(lastRefreshStartTime.timeIntervalSinceNow) < RefreshManager.minTimeBetweenRefreshes {
                // if it's been less than minTimeBetweenRefreshes since our last refresh, don't do another one. Effectively throttling user refreshes a little bit
                DispatchQueue.global().async {
                    Thread.sleep(forTimeInterval: 1.second)
                    ServerNotificationsHelper.shared.firePodcastsUpdated()
                    NotificationCenter.default.post(name: ServerNotifications.podcastRefreshThrottled, object: nil)
                }
                
                return
            }
        }
        
        UserDefaults.standard.set(Date(), forKey: ServerConstants.UserDefaults.lastRefreshStartTime)
        let podcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        
        DispatchQueue.global().async {
            MainServerHandler.shared.refresh(podcasts: podcasts) { [weak self] refreshResponse in
                guard let self = self else { return }
                
                self.processPodcastRefreshResponse(refreshResponse, completion: nil)
            }
        }
    }
    
    public func refreshPodcasts(completion: @escaping (RefreshFetchResult) -> Void) {
        DispatchQueue.global().async {
            let podcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
            MainServerHandler.shared.refresh(podcasts: podcasts) { [weak self] refreshResponse in
                guard let self = self else { return }
                
                self.processPodcastRefreshResponse(refreshResponse, completion: completion)
            }
        }
    }
    
    public func cancelAllRefreshes() {
        refreshQueue.cancelAllOperations()
    }
    
    private func processPodcastRefreshResponse(_ refreshResponse: PodcastRefreshResponse?, completion: ((RefreshFetchResult) -> Void)?) {
        guard let response = refreshResponse, response.success() else {
            FileLog.shared.addMessage("Podcast refresh failed with message: \(refreshResponse?.message ?? "none"). See previous log for more details.")
            ServerNotificationsHelper.shared.firePodcastRefreshFailed()
            completion?(.failed)
            
            return
        }
        
        if let result = response.result {
            let refreshOperation = RefreshOperation(result: result, completionHandler: completion)
            refreshQueue.addOperation(refreshOperation)
        }
    }
}
