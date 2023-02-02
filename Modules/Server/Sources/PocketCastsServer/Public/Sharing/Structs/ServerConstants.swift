import Foundation

public enum ServerConstants {
    public enum Urls {
        public static func main() -> String {
            production() ? "https://refresh.pocketcasts.com/" : "https://refresh.pocketcasts.net/"
        }

        public static func api() -> String {
            production() ? "https://api.pocketcasts.com/" : "https://api.pocketcasts.net/"
        }

        public static func cache() -> String {
            production() ? "https://cache.pocketcasts.com/" : "https://podcast-api.pocketcasts.net/"
        }

        public static func sharing() -> String {
            production() ? "https://sharing.pocketcasts.com/" : "https://sharing.pocketcasts.net/"
        }

        public static func discover() -> String {
            production() ? "https://static.pocketcasts.com/discover/" : "https://static.pocketcasts.net/discover/"
        }

        public static func image() -> String {
            production() ? "https://static.pocketcasts.com/" : "https://static.pocketcasts.net/"
        }

        public static func files() -> String {
            production() ? "https://files.pocketcasts.com/files/" : "https://files.pocketcasts.com/files/"
        }

        public static func share() -> String {
            production() ? "https://pca.st/" : "https://pcast.pocketcasts.net/"
        }

        public static func lists() -> String {
            production() ? "https://lists.pocketcasts.com/" : "https://lists.pocketcasts.net/"
        }

        public static let support = "https://support.pocketcasts.com/ios/"
        public static let cancelSubscription = "https://support.pocketcasts.com/article/subscription-info/"
        public static let termsOfUse = "https://support.pocketcasts.com/article/terms-of-use/"
        public static let privacyPolicy = "https://support.pocketcasts.com/article/privacy-policy/"
        public static let plusInfo = "https://pocketcasts.com/plus/"
        public static let pocketcastsDotCom = "https://pocketcasts.com/"
        public static let automatticDotCom = "https://automattic.com/"
        public static let automatticWorkWithUs = "https://automattic.com/work-with-us/"
        public static let appStoreReview = "https://itunes.apple.com/app/id414834813?action=write-review"
    }

    private static func production() -> Bool {
        ServerConfig.shared.syncDelegate?.production() ?? true
    }

    public enum HttpConstants {
        public static let ok = 200
        public static let notModified = 304
        public static let unauthorized = 401
        public static let notFound = 404
        public static let serverError = 500
        public static let badRequest = 400
        public static let conflict = 409
    }

    public enum HttpHeaders {
        public static let lastModified = "Last-Modified"
        public static let ifModifiedSince = "If-Modified-Since"
        public static let ifNoneMatch = "If-None-Match"
        public static let contentType = "Content-Type"
        public static let accept = "Accept"
        public static let userAgent = "User-Agent"
        public static let authorization = "Authorization"
        public static let expires = "Expires"
        public static let cacheControl = "Cache-Control"
        public static let date = "Date"
        public static let etag = "ETag"
    }

    public enum Timeouts {
        static let sync = 60 as TimeInterval
        static let general = 60 as TimeInterval
        static let cache = 30 as TimeInterval
    }

    public enum Values {
        static let apiScope = "mobile"
        static let deviceTypeiOS: Int32 = 1
        static let syncingEmailKey = "SJSyncingEmail"
        static let syncingPasswordKey = "SJSyncingPwd"
        static let syncingV2TokenKey = "SJSyncV2Token"
        static let refreshTokenKey = "SJRefreshToken"
        static let appleAuthUserIDKey = "SJAppleAuthUserID"
        public static let appUserAgent = "Pocket Casts"
        static let customStorageUsed = "SJCustomStorageUsed"
        static let customStorageNumFiles = "SJCustomStorageNumFiles"
        static let customStorageUserLimit = "SJCustomStorageUserLimit"

        static let oldEpisodeCutoff = 2.weeks
    }

    public enum UserDefaults {
        static let lastModifiedServerDate = "PCLastModifiedServerDate"
        static let lastSyncStartDate = "PCLastSyncStartDate"
        static let lastRefreshStartTime = "LastRefreshStartTime"
        static let lastRefreshEndTime = "SJLastRefreshDate"
        static let lastSyncTime = "SJLastSyncDate"
        static let syncingEmailLegacy = "SJSyncingEmail"
        static let historyServerLastModified = "SJHistoryServerLastModified"
        static let upNextServerLastModified = "SJUpNextServerLastModified"
        static let lastClearHistoryDate = "SJLastClearHistoryDate"
        static let pushToken = "SJPushToken"
        static let subscriptionPaid = "SJSubscriptionPaid"
        static let subscriptionExpiryDate = "SJSubscriptionExpiryDate"
        static let subscriptionAutoRenewing = "SJSubscriptionAutorenewing"
        static let subscriptionPlatform = "SJSubscriptionPlatform"
        static let subscriptionGiftDays = "SJSubscriptionGiftDays"
        static let subscriptionGiftAcknowledgement = "SJSubscriptionGiftAcknowledgement"
        public static let subscriptionFrequency = "SJSubscriptionFrequency"
        static let subscriptionPodcasts = "SJSubscriptionPodcasts"
        static let subscriptionType = "SJSubscriptionType"
        static let marketingOptInKey = "SJMarketingOptIn"
        static let marketingOptInNeedsSyncKey = "SJMarketingOptInNeedsSync"
        static let subscriptionGiftAcknowledgementNeedsSyncKey = "SJGiftAcknowledgementNeedsSync"
        static let filesLastModifiedKey = "UserFilesLastModified"
        static let statsStartDate = "StatsStartDate"
        static let statsSyncStatus = "StatsSyncStatus"
        static let statsDynamicSpeedSeconds = "StatsDynamicSpeed"
        static let statsVariableSpeed = "StatsVariableSpeed"
        static let statsListenedTo = "StatsListenedTo"
        static let statsSkipped = "StatsSkipped"
        static let statsAutoSkip = "StatsIntroSKip"
        static let statsDynamicSpeedSecondsServer = "StatsDynamicSpeedServer"
        static let statsVariableSpeedServer = "StatsVariableSpeedServer"
        static let statsListenedToServer = "StatsListenedToServer"
        static let statsSkippedServer = "StatsSkippedServer"
        static let statsAutoSkipServer = "StatsIntroSkipServer"
        static let statsStartedDateServer = "StatsStartedDateServer"
        static let userId = "UserId"
    }

    public enum Limits {
        static let maxHistoryItems = 100
        static let maxEpisodesToSync = 2000
    }
}
