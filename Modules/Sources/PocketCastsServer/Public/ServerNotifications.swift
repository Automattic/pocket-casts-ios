import Foundation

public enum ServerNotifications {
    // Sync
    public static let syncStarted = NSNotification.Name(rawValue: "PCSyncStarted")
    public static let syncCompleted = NSNotification.Name(rawValue: "PCSyncDone")
    public static let syncFailed = NSNotification.Name(rawValue: "PCSyncFailed")
    public static let syncProgressPodcastCount = NSNotification.Name(rawValue: "PCSyncCount")
    public static let podcastsRefreshed = NSNotification.Name(rawValue: "PCRefreshed")
    public static let podcastRefreshFailed = NSNotification.Name(rawValue: "PCRefFailed")
    public static let podcastRefreshThrottled = NSNotification.Name(rawValue: "PCRefreshedThrottled")
    public static let syncProgressImportedPodcasts = NSNotification.Name(rawValue: "PCSyncPodcastsDone")
    public static let syncProgressPodcastUpto = NSNotification.Name(rawValue: "PCSyncUpto")
    public static let episodeTypeOrLengthChanged = NSNotification.Name(rawValue: "SJEpisodeTypeChanged")

    // IAP notifications
    public static let iapProductsUpdated = NSNotification.Name(rawValue: "SJIapProductsUpdated")
    public static let iapProductsFailed = NSNotification.Name(rawValue: "SJIapProductsFailed")
    public static let iapPurchaseCompleted = NSNotification.Name(rawValue: "SJIapPurchaseCompleted")
    public static let iapPurchaseDeferred = NSNotification.Name(rawValue: "SJIapPurchaseDeferred")
    public static let iapPurchaseFailed = NSNotification.Name(rawValue: "SJIapPurchaseFailed")
    public static let iapPurchaseCancelled = NSNotification.Name(rawValue: "SJIapPurchaseCancelled")
    public static let subscriptionStatusChanged = NSNotification.Name(rawValue: "SJSubscriptionStatusChanged")

    // User Episode
    public static let userEpisodeUploadProgress = NSNotification.Name(rawValue: "SJUserEpisodeUploadProgress")
    public static let userEpisodesRefreshFailed = NSNotification.Name(rawValue: "SJUserEpisodesRefreshFailed")
    public static let userEpisodesRefreshed = NSNotification.Name(rawValue: "SJUserEpisodesRefreshed")
    public static let userEpisodeUploadStatusChanged = NSNotification.Name(rawValue: "SJUserEpisodeUploadChanged")
}

public extension NSNotification.Name {
    /// Fired before the user will be signed out
    static let serverUserWillBeSignedOut = NSNotification.Name("Server.User.WillBeSignedOut")
}
