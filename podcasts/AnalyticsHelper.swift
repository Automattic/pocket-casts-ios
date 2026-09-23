#if !os(watchOS)
    import Firebase
#endif

import Foundation
import os
import PocketCastsUtils

enum AnalyticsHelper {
    /// Whether the user has opted out of analytics or not
    static var optedOut: Bool {
        #if APPCLIP
        return true
        #else
        return Settings.analyticsOptOut()
        #endif
    }

    static func openedCategory(categoryId: Int, region: String) {
        logEvent("category_open", parameters: ["id": categoryId, "region": region])
        logEvent("category_page_open_\(categoryId)", parameters: nil)
    }

    static func openedFeaturedPodcast() {
        logEvent("featured_podcast_clicked", parameters: nil)
    }

    static func subscribedToFeaturedPodcast() {
        logEvent("featured_podcast_subscribed", parameters: nil)
    }

    static func userGuideOpened() {
        logEvent("user_guide_opened", parameters: nil)
    }

    static func userGuideEmail(feedback: Bool) {
        if feedback {
            userGuideEmailFeedback()
            Analytics.track(.settingsLeaveFeedback)
        } else {
            userGuideEmailSupport()
            Analytics.track(.settingsGetSupport)
        }
    }

    static func userGuideEmailSupport() {
        logEvent("user_guide_email", parameters: nil)
    }

    static func userGuideEmailFeedback() {
        logEvent("user_guide_feedback", parameters: nil)
    }

    static func downloadFromNotification() {
        logEvent("notification_download", parameters: nil)
    }

    static func archiveFromNotification() {
        logEvent("notification_archive", parameters: nil)
    }

    static func addToUpNextFromNotification(playFirst: Bool) {
        if playFirst {
            logEvent("notification_add_to_up_next_top", parameters: nil)
        } else {
            logEvent("notification_add_to_up_next_bottom", parameters: nil)
        }
    }

    static func playNowFromNotification() {
        logEvent("notification_play_now", parameters: nil)
    }

    static func sharedPodcast() {
        logEvent("shared_podcast", parameters: nil)
    }

    static func sharedPodcastList() {
        logEvent("shared_podcast_list", parameters: nil)
    }

    static func navigatedToDiscover() {
        logEvent("discover_open", parameters: nil)
    }

    static func playedEpisode() {
        logEvent("played_episode", parameters: nil)
    }

    static func subscribedToPodcast() {
        logEvent("subscribed_to_podcast", parameters: nil)
    }

    // MARK: - List Analytics

    static func podcastEpisodePlayedFromList(listId: String, podcastUuid: String) {
        let properties = ["list_id": listId, "podcast_uuid": podcastUuid]
        Analytics.track(.discoverListEpisodePlay, properties: properties)
        bumpStat("discover_list_episode_play", parameters: properties)
    }

    static func podcastSubscribedFromList(listId: String, podcastUuid: String, listDateTime: String? = nil) {
        var properties = ["list_id": listId, "podcast_uuid": podcastUuid]
        if let listDateTime {
            properties["list_datetime"] = listDateTime
        }
        Analytics.track(.discoverListPodcastSubscribed, properties: properties)
        bumpStat("discover_list_podcast_subscribe", parameters: properties)
    }

    static func podcastTappedFromList(listId: String, podcastUuid: String, listDateTime: String? = nil, source: String? = nil) {
        var properties = ["list_id": listId, "podcast_uuid": podcastUuid]
        if let listDateTime {
            properties["list_datetime"] = listDateTime
        }
        if let source {
            properties["source"] = source
        }
        Analytics.track(.discoverListPodcastTapped, properties: properties)
        bumpStat("discover_list_podcast_tap", parameters: properties)
    }

    static func adTapped(categoryName: String, region: String, podcastUUID: String, categoryID: Int) {
        let properties: [String: Any] = ["name": categoryName, "region": region, "id": categoryID, "podcast_id": podcastUUID]
        Analytics.track(.discoverAdCategoryTapped, properties: properties)
    }

    static func adSubscribed(categoryName: String, region: String, podcastUUID: String, categoryID: Int) {
        let properties: [String: Any] = ["name": categoryName, "region": region, "id": categoryID, "podcast_id": podcastUUID]
        Analytics.track(.discoverAdCategorySubscribed, properties: properties)
    }

    static func podcastEpisodeTapped(fromList listId: String, podcastUuid: String, episodeUuid: String, source: String? = nil) {
        var properties = ["list_id": listId, "podcast_uuid": podcastUuid, "episode_uuid": episodeUuid]
        if let source {
            properties["source"] = source
        }
        Analytics.track(.discoverListEpisodeTapped, properties: properties)
        bumpStat("discover_list_podcast_episode_tap", parameters: properties)
    }

    static func listShowAllTapped(listId: String, dateTime: String? = nil) {
        var properties = ["list_id": listId]
        if let dateTime {
            properties["list_datetime"] = dateTime
        }
        Analytics.track(.discoverListShowAllTapped, properties: properties)
        bumpStat("discover_list_show_all", parameters: properties)
    }

    static func listImpression(listId: String, category: String?, source: String? = nil) {
        var properties = ["list_id": listId]
        if let category {
            properties["category"] = category
        }
        if let source {
            properties["source"] = source
        }
        Analytics.track(.discoverListImpression, properties: properties)
        bumpStat("discover_list_impression", parameters: properties)
    }

    static func bannerImpression(adID: String, location: String) {
        let properties = ["id": adID, "location": location]
        Analytics.track(.bannerAdImpression, properties: properties)
        bumpStat("banner_ad_impression", parameters: properties)
    }

    static func bannerTapped(adID: String, location: String) {
        let properties = ["id": adID, "location": location]
        Analytics.track(.bannerAdTapped, properties: properties)
        bumpStat("banner_ad_tapped", parameters: properties)
    }

    static func bannerReport(adID: String, reason: String, location: String) {
        let properties = ["id": adID, "location": location, "reason": reason]
        Analytics.track(.bannerAdReport, properties: properties)
        bumpStat("banner_ad_report", parameters: properties)
    }

    static func forceTouchPlay() {
        logEvent("play_force_touch", parameters: nil)
    }

    static func forceTouchPause() {
        logEvent("pause_force_touch", parameters: nil)
    }

    static func forceTouchMarkPlayed() {
        logEvent("mark_as_played_force_touch", parameters: nil)
    }

    static func forceTouchTopFilter() {
        logEvent("top_filter_force_touch", parameters: nil)
    }

    static func forceTouchPodcast() {
        logEvent("podcast_force_touch", parameters: nil)
    }

    static func forceTouchDiscover() {
        logEvent("discover_force_touch", parameters: nil)
    }

    static func didConnectToChromecast() {
        logEvent("connected_to_chromecast", parameters: nil)
    }

    static func didChooseIcon(iconName: String?) {
        if let name = iconName {
            // Firebase doesn't like dashes (Event name must contain only letters, numbers, or underscores)
            logEvent("icon_\(name.replacingOccurrences(of: "-", with: "_"))", parameters: nil)
        } else {
            logEvent("icon_default", parameters: nil)
        }
    }

    static func siriSleeptimer() {
        logEvent("siri_sleep_timer", parameters: nil)
    }

    static func siriChapterChanged() {
        logEvent("siri_chapter_change", parameters: nil)
    }

    static func siriSurpriseMe() {
        logEvent("siri_surprise_me", parameters: nil)
    }

    static func siriUpNext() {
        logEvent("siri_up_next", parameters: nil)
    }

    static func siriPause() {
        logEvent("siri_pause", parameters: nil)
    }

    static func siriMarkAsPlayed() {
        logEvent("siri_mark_as_played", parameters: nil)
    }

    static func siriResume() {
        logEvent("siri_resume", parameters: nil)
    }

    static func siriPlayPodcast() {
        logEvent("siri_play_podcast", parameters: nil)
    }

    static func siriPlayTopFilter() {
        logEvent("siri_play_top_filter", parameters: nil)
    }

    #if !os(watchOS) && !APPCLIP && !os(tvOS)
        static func tabSelected(tab: MainTabBarController.Tab) {
            switch tab {
            case .podcasts:
                logEvent("podcast_tab_opened", parameters: nil)
            case .filter:
                logEvent("filter_tab_opened", parameters: nil)
            case .profile:
                logEvent("profile_tab_opened", parameters: nil)
            case .upNext:
                logEvent("upnext_tab_opened", parameters: nil)
            case .discover: break // we don't log this case, since it's handled in did load
            }
        }
    #endif

    static func nowPlayingOpened() {
        logEvent("now_playing_open", parameters: nil)
    }

    static func upNextOpened() {
        logEvent("up_next_open", parameters: nil)
    }

    static func podcastOpened(uuid: String) {
        logEvent("podcast_open", parameters: ["podcastUuid": uuid])
    }

    static func episodeOpened(podcastUuid: String, episodeUuid: String) {
        logEvent("episode_open", parameters: ["podcastUuid": podcastUuid, "episodeUuid": episodeUuid])
    }

    static func playerShowNotesOpened() {
        logEvent("now_playing_notes_open", parameters: nil)
    }

    static func chaptersOpened() {
        logEvent("now_playing_chapters_open", parameters: nil)
    }

    static func accountDeleted() {
        logEvent("account_deleted", parameters: nil)
    }
}

// MARK: - Plus Upgrades

#if os(iOS)
    extension AnalyticsHelper {
        static func plusPlanPurchased() {
            logEvent(AnalyticsEventPurchase)
        }
    }

    // MARK: - Account Creation

    extension AnalyticsHelper {
        static func createAccountDismissed() {
            logEvent("close_account_missing")
        }
    }

    // MARK: - Folders

    extension AnalyticsHelper {
        static func folderCreated() {
            logEvent("folder_created")
        }
    }
#endif // End iOS Only Check

// MARK: - Private

private extension AnalyticsHelper {
    static let logger = Logger()

    static func bumpStat(_ name: String, parameters: [String: Any]? = nil) {
        Self.logEvent(name, parameters: parameters)
    }

    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard optedOut == false else { return }

        // assuming for now we don't want analytics on a watch
        #if !os(watchOS)
            Firebase.Analytics.logEvent(name, parameters: parameters)

        if FeatureFlag.firebaseLogging.enabled {
                if let parameters {
                    logger.debug("🟢 Tracked: \(name) \(parameters)")
                } else {
                    logger.debug("🟢 Tracked: \(name)")
                }
            }
        #endif
    }
}
