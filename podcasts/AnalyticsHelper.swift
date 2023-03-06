#if !os(watchOS)
    import Firebase
#endif

import Foundation
import os

class AnalyticsHelper {
    /// Whether the user has opted out of analytics or not
    static var optedOut: Bool {
        Settings.analyticsOptOut()
    }

    class func openedCategory(categoryId: Int, region: String) {
        logEvent("category_open", parameters: ["id": categoryId, "region": region])
        logEvent("category_page_open_\(categoryId)", parameters: nil)
    }

    class func openedFeaturedPodcast() {
        logEvent("featured_podcast_clicked", parameters: nil)
    }

    class func subscribedToFeaturedPodcast() {
        logEvent("featured_podcast_subscribed", parameters: nil)
    }

    class func userGuideOpened() {
        logEvent("user_guide_opened", parameters: nil)
    }

    class func userGuideEmail(feedback: Bool) {
        if feedback {
            userGuideEmailFeedback()
        } else {
            userGuideEmailSupport()
        }
    }

    class func userGuideEmailSupport() {
        logEvent("user_guide_email", parameters: nil)
    }

    class func userGuideEmailFeedback() {
        logEvent("user_guide_feedback", parameters: nil)
    }

    class func downloadFromNotification() {
        logEvent("notification_download", parameters: nil)
    }

    class func archiveFromNotification() {
        logEvent("notification_archive", parameters: nil)
    }

    class func addToUpNextFromNotification(playFirst: Bool) {
        if playFirst {
            logEvent("notification_add_to_up_next_top", parameters: nil)
        } else {
            logEvent("notification_add_to_up_next_bottom", parameters: nil)
        }
    }

    class func playNowFromNotification() {
        logEvent("notification_play_now", parameters: nil)
    }

    class func sharedPodcast() {
        logEvent("shared_podcast", parameters: nil)
    }

    class func sharedPodcastList() {
        logEvent("shared_podcast_list", parameters: nil)
    }

    class func sharedEpisode() {
        logEvent("shared_episode", parameters: nil)
    }

    class func sharedEpisodeWithTimestamp() {
        logEvent("shared_episode_time", parameters: nil)
    }

    class func navigatedToDiscover() {
        logEvent("discover_open", parameters: nil)
    }

    class func playedEpisode() {
        logEvent("played_episode", parameters: nil)
    }

    class func subscribedToPodcast() {
        logEvent("subscribed_to_podcast", parameters: nil)
    }

    // MARK: - List Analytics

    class func podcastEpisodePlayedFromList(listId: String, podcastUuid: String) {
        let properties = ["list_id": listId, "podcast_uuid": podcastUuid]
        Analytics.track(.discoverListEpisodePlay, properties: properties)
        bumpStat("discover_list_episode_play", parameters: properties)
    }

    class func podcastSubscribedFromList(listId: String, podcastUuid: String) {
        let properties = ["list_id": listId, "podcast_uuid": podcastUuid]
        Analytics.track(.discoverListPodcastSubscribed, properties: properties)
        bumpStat("discover_list_podcast_subscribe", parameters: properties)
    }

    class func podcastTappedFromList(listId: String, podcastUuid: String) {
        let properties = ["list_id": listId, "podcast_uuid": podcastUuid]
        Analytics.track(.discoverListPodcastTapped, properties: properties)
        bumpStat("discover_list_podcast_tap", parameters: properties)
    }

    class func podcastEpisodeTapped(fromList listId: String, podcastUuid: String, episodeUuid: String) {
        let properties = ["list_id": listId, "podcast_uuid": podcastUuid, "episode_uuid": episodeUuid]

        Analytics.track(.discoverListEpisodeTapped, properties: properties)
        bumpStat("discover_list_podcast_episode_tap", parameters: properties)
    }

    class func listShowAllTapped(listId: String) {
        let properties = ["list_id": listId]
        Analytics.track(.discoverListShowAllTapped, properties: properties)
        bumpStat("discover_list_show_all", parameters: properties)
    }

    class func listImpression(listId: String) {
        Analytics.track(.discoverListImpression, properties: ["list_id": listId])
        bumpStat("discover_list_impression", parameters: ["list_id": listId])
    }

    class func forceTouchPlay() {
        logEvent("play_force_touch", parameters: nil)
    }

    class func forceTouchPause() {
        logEvent("pause_force_touch", parameters: nil)
    }

    class func forceTouchMarkPlayed() {
        logEvent("mark_as_played_force_touch", parameters: nil)
    }

    class func forceTouchTopFilter() {
        logEvent("top_filter_force_touch", parameters: nil)
    }

    class func forceTouchPodcast() {
        logEvent("podcast_force_touch", parameters: nil)
    }

    class func forceTouchDiscover() {
        logEvent("discover_force_touch", parameters: nil)
    }

    class func didConnectToChromecast() {
        logEvent("connected_to_chromecast", parameters: nil)
    }

    class func didChooseIcon(iconName: String?) {
        if let name = iconName {
            // Firebase doesn't like dashes (Event name must contain only letters, numbers, or underscores)
            logEvent("icon_\(name.replacingOccurrences(of: "-", with: "_"))", parameters: nil)
        } else {
            logEvent("icon_default", parameters: nil)
        }
    }

    class func siriSleeptimer() {
        logEvent("siri_sleep_timer", parameters: nil)
    }

    class func siriChapterChanged() {
        logEvent("siri_chapter_change", parameters: nil)
    }

    class func siriSurpriseMe() {
        logEvent("siri_surprise_me", parameters: nil)
    }

    class func siriUpNext() {
        logEvent("siri_up_next", parameters: nil)
    }

    class func siriPause() {
        logEvent("siri_pause", parameters: nil)
    }

    class func siriResume() {
        logEvent("siri_resume", parameters: nil)
    }

    class func siriPlayPodcast() {
        logEvent("siri_play_podcast", parameters: nil)
    }

    class func siriPlayAllFilter() {
        logEvent("siri_play_all_filter", parameters: nil)
    }

    class func siriPlayTopFilter() {
        logEvent("siri_play_top_filter", parameters: nil)
    }

    class func siriOpenFilter() {
        logEvent("siri_open_filter", parameters: nil)
    }

    class func tourStarted(tourName: String) {
        logEvent("\(tourName)_tour_started", parameters: nil)
    }

    class func tourCompleted(tourName: String) {
        logEvent("\(tourName)_tour_completed", parameters: nil)
    }

    class func tourCancelled(tourName: String, at step: Int) {
        logEvent("\(tourName)_tour_cancelled_\(step)", parameters: nil)
    }

    #if !os(watchOS)
        class func tabSelected(tab: MainTabBarController.Tab) {
            switch tab {
            case .podcasts:
                logEvent("podcast_tab_open", parameters: nil)
            case .filter:
                logEvent("filter_tab_open", parameters: nil)
            case .profile:
                logEvent("profile_tab_open", parameters: nil)

            case .discover: break // we don't log this case, since it's handled in did load
            }
        }
    #endif

    class func nowPlayingOpened() {
        logEvent("now_playing_open", parameters: nil)
    }

    class func upNextOpened() {
        logEvent("up_next_open", parameters: nil)
    }

    class func filterOpened() {
        logEvent("filter_opened", parameters: nil)
    }

    class func podcastOpened(uuid: String) {
        logEvent("podcast_open", parameters: ["podcastUuid": uuid])
    }

    class func episodeOpened(podcastUuid: String, episodeUuid: String) {
        logEvent("episode_open", parameters: ["podcastUuid": podcastUuid, "episodeUuid": episodeUuid])
    }

    class func playerShowNotesOpened() {
        logEvent("now_playing_notes_open", parameters: nil)
    }

    class func chaptersOpened() {
        logEvent("now_playing_chapters_open", parameters: nil)
    }

    class func accountDeleted() {
        logEvent("account_deleted", parameters: nil)
    }
}

// MARK: - Plus Upgrades

#if os(iOS)
    extension AnalyticsHelper {
        static func plusUpgradeViewed(source: PlusUpgradeViewSource) {
            Analytics.track(.plusPromotionShown, properties: ["source": source.rawValue])

            logPromotionEvent(AnalyticsEventViewPromotion,
                              promotionId: source.promotionId(),
                              promotionName: source.promotionName())
        }

        static func plusUpgradeConfirmed(source: PlusUpgradeViewSource) {
            Analytics.track(.plusPromotionUpgradeButtonTapped, properties: ["source": source.rawValue])

            logPromotionEvent(AnalyticsEventSelectPromotion,
                              promotionId: source.promotionId(),
                              promotionName: source.promotionName())
        }

        static func plusUpgradeDismissed(source: PlusUpgradeViewSource) {
            Analytics.track(.plusPromotionDismissed, properties: ["source": source.rawValue])

            logPromotionEvent("close_promotion",
                              promotionId: source.promotionId(),
                              promotionName: source.promotionName())
        }

        static func plusAddToCart(identifier: String) {
            guard let product = IapHelper.shared.getProductWithIdentifier(identifier: identifier) else {
                return
            }

            let price = product.price
            let currency = product.priceLocale.currencyCode ?? ""
            let name = product.localizedTitle

            let item: [String: Any] = [
                AnalyticsParameterItemID: identifier,
                AnalyticsParameterItemName: name,
                AnalyticsParameterPrice: price,
                AnalyticsParameterQuantity: 1
            ]

            var parameters: [String: Any] = [
                AnalyticsParameterCurrency: currency,
                AnalyticsParameterValue: price,
                AnalyticsParameterItems: [item]
            ]

            // Log that a free trial was used
            if IapHelper.shared.isEligibleForFreeTrial(), product.introductoryPrice?.paymentMode == .freeTrial {
                parameters[AnalyticsParameterCoupon] = "FREE_TRIAL"
            }

            logEvent(AnalyticsEventAddToCart, parameters: parameters)
        }

        static func plusPlanPurchased() {
            logEvent(AnalyticsEventPurchase)
        }
    }

    // MARK: - Account Creation

    extension AnalyticsHelper {
        static func createAccountDismissed() {
            logEvent("close_account_missing")
        }

        static func createAccountConfirmed() {
            logEvent("select_create_account")
        }

        static func createAccountSignIn() {
            logEvent("select_sign_in_account")
        }
    }

    // MARK: - Folders

    extension AnalyticsHelper {
        static func folderCreated() {
            logEvent("folder_created")
        }
    }

    // MARK: - Promotion Events

    private extension AnalyticsHelper {
        // Helper method to log a Firebase promotion event
        static func logPromotionEvent(_ name: String, promotionId: String, promotionName: String) {
            let parameters = [
                AnalyticsParameterPromotionID: promotionId,
                AnalyticsParameterPromotionName: promotionName
            ]

            logEvent(name, parameters: parameters)
        }
    }
#endif // End iOS Only Check

// MARK: - Private

private extension AnalyticsHelper {
    static let logger = Logger()

    class func bumpStat(_ name: String, parameters: [String: Any]? = nil) {
        Self.logEvent(name, parameters: parameters)
    }

    class func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard optedOut == false else { return }

        // assuming for now we don't want analytics on a watch
        #if !os(watchOS)
            Firebase.Analytics.logEvent(name, parameters: parameters)

        if FeatureFlag.firebaseLogging.enabled {
                if let parameters = parameters {
                    logger.debug("🟢 Tracked: \(name) \(parameters)")
                } else {
                    logger.debug("🟢 Tracked: \(name)")
                }
            }
        #endif
    }
}
