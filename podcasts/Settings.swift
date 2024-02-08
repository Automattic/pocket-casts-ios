import PocketCastsDataModel
#if !os(watchOS)
    import Firebase
#endif
import PocketCastsServer
import UIKit

class Settings: NSObject {
    // MARK: - Library Type

    private static let podcastLibraryGridTypeKey = "SJPodcastLibraryGridType"
    private static var cachedlibrarySortType: LibraryType?
    class func setLibraryType(_ type: LibraryType) {
        UserDefaults.standard.set(type.rawValue, forKey: Settings.podcastLibraryGridTypeKey)
        cachedlibrarySortType = type
    }

    class func libraryType() -> LibraryType {
        if let type = cachedlibrarySortType {
            return type
        }

        let storedValue = UserDefaults.standard.integer(forKey: Settings.podcastLibraryGridTypeKey)
        if let type = LibraryType(rawValue: storedValue) {
            cachedlibrarySortType = type

            return type
        }

        return LibraryType.threeByThree // default value
    }

    // MARK: - Podcast Badge

    private static let badgeKey = "SJBadgeType"
    class func podcastBadgeType() -> BadgeType {
        let storedBadgeType = UserDefaults.standard.integer(forKey: Settings.badgeKey)

        if let type = BadgeType(rawValue: storedBadgeType) {
            return type
        }

        return .off
    }

    class func setPodcastBadgeType(_ badgeType: BadgeType) {
        UserDefaults.standard.set(badgeType.rawValue, forKey: Settings.badgeKey)
    }

    // MARK: - Up Next Auto Download

    private static let autoDownloadUpNext = "SJAutoDownloadUpNext"
    class func downloadUpNextEpisodes() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.autoDownloadUpNext)
    }

    class func setDownloadUpNextEpisodes(_ download: Bool) {
        UserDefaults.standard.set(download, forKey: Settings.autoDownloadUpNext)
        trackValueToggled(.settingsAutoDownloadUpNextToggled, enabled: download)
    }

    // MARK: - Mobile Data

    private static let allowCellularDownloadKey = "SJUserCellular"
    class func mobileDataAllowed() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.allowCellularDownloadKey)
    }

    class func setMobileDataAllowed(_ allow: Bool, userInitiated: Bool = false) {
        UserDefaults.standard.set(allow, forKey: Settings.allowCellularDownloadKey)

        guard userInitiated else { return }
        trackValueToggled(.settingsStorageWarnBeforeUsingDataToggled, enabled: allow)
    }

    // MARK: - Auto Download Mobile Data

    private static let allowCellularAutoDownloadKey = "SJUserCellularAutoDownload"
    class func autoDownloadMobileDataAllowed() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.allowCellularAutoDownloadKey)
    }

    class func setAutoDownloadMobileDataAllowed(_ allow: Bool, userInitiated: Bool = false) {
        UserDefaults.standard.set(allow, forKey: Settings.allowCellularAutoDownloadKey)

        guard userInitiated else { return }
        trackValueToggled(.settingsAutoDownloadOnlyOnWifiToggled, enabled: !allow)
    }

    // MARK: - Auto Download

    private static let autoDownloadEnabledKey = "AutoDownloadEnabled"
    class func autoDownloadEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.autoDownloadEnabledKey)
    }

    class func setAutoDownloadEnabled(_ allow: Bool, userInitiated: Bool = false) {
        UserDefaults.standard.set(allow, forKey: Settings.autoDownloadEnabledKey)

        guard userInitiated else { return }
        trackValueToggled(.settingsAutoDownloadNewEpisodesToggled, enabled: allow)
    }

    class func shouldDeleteWhenPlayed() -> Bool {
        let finishedAction = UserDefaults.standard.integer(forKey: Constants.UserDefaults.episodeFinishedAction)

        return finishedAction == PodcastFinishedAction.delete.rawValue
    }

    class func setShouldDeleteWhenPlayed(_ shouldDelete: Bool) {
        let finishedAction = shouldDelete ? PodcastFinishedAction.delete : PodcastFinishedAction.doNothing

        UserDefaults.standard.setValue(finishedAction.rawValue, forKey: Constants.UserDefaults.episodeFinishedAction)
    }

    // MARK: - Default Archive Hiding

    private static let defaultArchiveBehaviour = "SJDefaultArchive"
    class func showArchivedDefault() -> Bool {
        UserDefaults.standard.bool(forKey: defaultArchiveBehaviour)
    }

    class func setShowArchivedDefault(_ showArchived: Bool) {
        UserDefaults.standard.set(showArchived, forKey: defaultArchiveBehaviour)

        trackValueChanged(.settingsGeneralArchivedEpisodesChanged, value: showArchived ? "show" : "hide")
    }

    // MARK: - Primary Row Action

    private static let primaryRowActionKey = "SJRowAction"
    private static var cachedPrimaryRowAction: PrimaryRowAction? // we cache this because it's used in lists
    class func primaryRowAction() -> PrimaryRowAction {
        if FeatureFlag.settingsSync.enabled {
            return SettingsStore.appSettings.rowAction
        } else {
            if let action = cachedPrimaryRowAction { return action }
            let storedValue = UserDefaults.standard.integer(forKey: primaryRowActionKey)
            return PrimaryRowAction(rawValue: Int32(storedValue)) ?? .stream
        }
    }

    class func setPrimaryRowAction(_ action: PrimaryRowAction) {
        if FeatureFlag.settingsSync.enabled {
            SettingsStore.appSettings.rowAction = action
        } else {
            UserDefaults.standard.set(
                action.rawValue,
                forKey: primaryRowActionKey
            )
        }
        cachedPrimaryRowAction = action

        trackValueChanged(.settingsGeneralRowActionChanged, value: action)
    }

    // MARK: - Podcast Sort Order

    class func homeFolderSortOrder() -> LibrarySort {
        let sortInt = ServerSettings.homeGridSortOrder()
        if let librarySort = LibrarySort(rawValue: sortInt) {
            return librarySort
        }

        return .dateAddedNewestToOldest
    }

    class func setHomeFolderSortOrder(order: LibrarySort) {
        ServerSettings.setHomeGridSortOrder(order.rawValue, syncChange: true)
    }

    // MARK: - Podcast Grouping Default

    static let podcastGroupingDefaultKey = "SJDefaultPodcastGrouping"
    private static var cachedPodcastGrouping: PodcastGrouping?
    class func defaultPodcastGrouping() -> PodcastGrouping {
        guard FeatureFlag.settingsSync.enabled == false else {
            return SettingsStore.appSettings.episodeGrouping
        }

        if let grouping = cachedPodcastGrouping { return grouping }

        let storedValue = UserDefaults.standard.integer(forKey: podcastGroupingDefaultKey)
        let defaultGrouping = PodcastGrouping(rawValue: Int32(storedValue)) ?? .none
        cachedPodcastGrouping = defaultGrouping

        return defaultGrouping
    }

    class func setDefaultPodcastGrouping(_ grouping: PodcastGrouping) {
        if FeatureFlag.settingsSync.enabled {
            SettingsStore.appSettings.episodeGrouping = grouping
        }
        UserDefaults.standard.set(grouping.rawValue, forKey: podcastGroupingDefaultKey)
        cachedPodcastGrouping = grouping

        trackValueChanged(.settingsGeneralEpisodeGroupingChanged, value: grouping)
    }

    // MARK: - Primary Up Next Swipe Action

    private static let primaryUpNextSwipeActionKey = "SJUpNextSwipe"
    private static var cachedPrimaryUpNextSwipeAction: PrimaryUpNextSwipeAction? // we cache this because it's used in lists
    class func primaryUpNextSwipeAction() -> PrimaryUpNextSwipeAction {
        if let action = cachedPrimaryUpNextSwipeAction { return action }

        let storedValue = UserDefaults.standard.integer(forKey: primaryUpNextSwipeActionKey)
        let primaryAction = PrimaryUpNextSwipeAction(rawValue: Int32(storedValue)) ?? .playNext
        cachedPrimaryUpNextSwipeAction = primaryAction

        return primaryAction
    }

    class func setPrimaryUpNextSwipeAction(_ action: PrimaryUpNextSwipeAction) {
        UserDefaults.standard.set(action.rawValue, forKey: primaryUpNextSwipeActionKey)
        cachedPrimaryUpNextSwipeAction = action

        trackValueChanged(.settingsGeneralUpNextSwipeChanged, value: action)
    }

    // MARK: - Play Up Next On Tap

    private static let playUpNextOnTapKey = "SJPlayUpNextOnTap"
    class func playUpNextOnTap() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.playUpNextOnTapKey)
    }

    class func setPlayUpNextOnTap(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: Settings.playUpNextOnTapKey)
    }

    // MARK: - Discover Region

    private static let chartRegion = "SJChartRegion"
    class func discoverRegion(discoverLayout: DiscoverLayout) -> String {
        var userRegion: String?
        if let savedRegion = UserDefaults.standard.string(forKey: chartRegion) {
            userRegion = savedRegion.lowercased()
        } else if let region = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String {
            userRegion = region.lowercased()
        }

        return convertRegion(userRegion: userRegion, discoverLayout: discoverLayout)
    }

    private class func convertRegion(userRegion: String?, discoverLayout: DiscoverLayout) -> String {
        guard let userRegion = userRegion else { return discoverLayout.defaultRegionCode }

        if let _ = discoverLayout.regions?[userRegion.lowercased()] {
            return userRegion
        }

        return discoverLayout.defaultRegionCode
    }

    class func setDiscoverRegion(region: String) {
        UserDefaults.standard.set(region, forKey: chartRegion)
        UserDefaults.standard.synchronize()

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.chartRegionChanged)
    }

    // MARK: - Auto Archiving

    private static let autoArchivePlayedAfterKey = "AutoArchivePlayedAfer"
    class func autoArchivePlayedAfter() -> TimeInterval {
        UserDefaults.standard.double(forKey: Settings.autoArchivePlayedAfterKey)
    }

    class func setAutoArchivePlayedAfter(_ after: TimeInterval, userInitiated: Bool = false) {
        UserDefaults.standard.set(after, forKey: Settings.autoArchivePlayedAfterKey)

        guard userInitiated else { return }
        if let archiveTime = AutoArchiveAfterTime(rawValue: after) {
            trackValueChanged(.settingsAutoArchivePlayedChanged, value: archiveTime)
        }
    }

    private static let autoArchiveInactiveAfterKey = "AutoArchiveInactiveAfer"
    class func autoArchiveInactiveAfter() -> TimeInterval {
        UserDefaults.standard.double(forKey: Settings.autoArchiveInactiveAfterKey)
    }

    class func setAutoArchiveInactiveAfter(_ after: TimeInterval, userInitiated: Bool = false) {
        UserDefaults.standard.set(after, forKey: Settings.autoArchiveInactiveAfterKey)

        guard userInitiated else { return }
        if let archiveTime = AutoArchiveAfterTime(rawValue: after) {
            trackValueChanged(.settingsAutoArchiveInactiveChanged, value: archiveTime)
        }
    }

    private static let archiveStarredEpisodesKey = "ArchiveStarredEpisodes"
    class func archiveStarredEpisodes() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.archiveStarredEpisodesKey)
    }

    class func setArchiveStarredEpisodes(_ archive: Bool, userInitiated: Bool = false) {
        UserDefaults.standard.set(archive, forKey: Settings.archiveStarredEpisodesKey)

        guard userInitiated else { return }
        trackValueToggled(.settingsAutoArchiveIncludeStarredToggled, enabled: archive)
    }

    // MARK: - App Info

    @objc class func appVersion() -> String {
        guard let infoDictionary = Bundle.main.infoDictionary, let shortVersion = infoDictionary["CFBundleShortVersionString"] as? String else {
            return "6.0" // this should never fail, but it's a nicer API to not return nil
        }

        return shortVersion
    }

    class func displayableVersion() -> String {
        #if STAGING
            return L10n.appVersion(Settings.appVersion(), Settings.buildNumber()) + " - STAGING"
        #else
            return L10n.appVersion(Settings.appVersion(), Settings.buildNumber())
        #endif
    }

    class func buildNumber() -> String {
        guard let infoDictionary = Bundle.main.infoDictionary, let buildNumber = infoDictionary[kCFBundleVersionKey as String] as? String else {
            return "1" // this should never fail, but it's a nicer API to not return nil
        }

        return buildNumber
    }

    // MARK: - Sleep Time

    private static let customSleepTimeKey = "CustomSleepTime"
    class func customSleepTime() -> TimeInterval {
        let savedTime = UserDefaults.standard.double(forKey: Settings.customSleepTimeKey)
        if savedTime < Constants.Limits.minSleepTime { return Constants.Limits.minSleepTime }

        return savedTime
    }

    class func setCustomSleepTime(_ time: TimeInterval) {
        let adjustedTime = time < Constants.Limits.minSleepTime ? Constants.Limits.minSleepTime : time
        UserDefaults.standard.set(adjustedTime, forKey: "CustomSleepTime")
    }

    // MARK: - CarPlay/Lock Screen actions

    private static let mediaSessionActionsKey = "MediaSessionActions"
    class func extraMediaSessionActionsEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.mediaSessionActionsKey)
    }

    class func setExtraMediaSessionActionsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Settings.mediaSessionActionsKey)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.extraMediaSessionActionsChanged)

        Settings.trackValueToggled(.settingsGeneralExtraPlaybackActionsToggled, enabled: enabled)
    }

    // MARK: - Legacy Bluetooth Support

    private static let legacyBtSupportKey = "LegacyBtSupport"
    class func legacyBluetoothModeEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.legacyBtSupportKey)
    }

    class func setLegacyBluetoothModeEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Settings.legacyBtSupportKey)
        Settings.trackValueToggled(.settingsGeneralLegacyBluetoothToggled, enabled: enabled)
    }

    // MARK: - Publish Chapter Titles

    private static let publishChapterTitlesKey = "PublishChapterTitles"
    class func publishChapterTitlesEnabled() -> Bool {
        if let isEnabled = UserDefaults.standard.value(forKey: Settings.publishChapterTitlesKey) as? Bool {
            return isEnabled
        }

        return true
    }

    class func setPublishChapterTitlesEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Settings.publishChapterTitlesKey)
    }

    // MARK: - User Episode Settings

    private static let userEpisodeSortByKey = "UserEpisodeSortBy"
    class func userEpisodeSortBy() -> Int {
        UserDefaults.standard.integer(forKey: userEpisodeSortByKey)
    }

    class func setUserEpisodeSortBy(_ value: Int) {
        UserDefaults.standard.set(value, forKey: userEpisodeSortByKey)
    }

    private static let userEpisodeAutoUploadKey = "UserEpisodeAutoUpload"
    class func userFilesAutoUpload() -> Bool {
        UserDefaults.standard.bool(forKey: userEpisodeAutoUploadKey)
    }

    class func setUserEpisodeAutoUpload(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: userEpisodeAutoUploadKey)
        trackValueToggled(.settingsFilesAutoUploadToCloudToggled, enabled: value)
    }

    private static let userEpisodeAutoAddToUpNextKey = "UserEpisodeAutoAddToUpNext"
    class func userEpisodeAutoAddToUpNext() -> Bool {
        UserDefaults.standard.bool(forKey: userEpisodeAutoAddToUpNextKey)
    }

    class func setUserEpisodeAutoAddToUpNext(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: userEpisodeAutoAddToUpNextKey)
        trackValueToggled(.settingsFilesAutoAddUpNextToggled, enabled: value)
    }

    private static let userEpisodeRemoveFileAfterPlayingKey = "UserEpisodeRemoveFileAfterPlaying"
    class func userEpisodeRemoveFileAfterPlaying() -> Bool {
        UserDefaults.standard.bool(forKey: userEpisodeRemoveFileAfterPlayingKey)
    }

    class func setUserEpisodeRemoveFileAfterPlaying(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: userEpisodeRemoveFileAfterPlayingKey)
        trackValueToggled(.settingsFilesDeleteLocalFileAfterPlayingToggled, enabled: value)
    }

    private static let userEpisodeRemoveFromCloudAfterPlayingKey = "UserEpisodeRemoveFromCloudAfterPlaying"
    class func userEpisodeRemoveFromCloudAfterPlaying() -> Bool {
        UserDefaults.standard.bool(forKey: userEpisodeRemoveFromCloudAfterPlayingKey)
    }

    class func setUserEpisodeRemoveFromCloudAfterPlayingKey(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: userEpisodeRemoveFromCloudAfterPlayingKey)
        trackValueToggled(.settingsFilesDeleteCloudFileAfterPlayingToggled, enabled: value)
    }

    // MARK: - Full Player Chapters Expanded

    private static let playerChaptersExpandedKey = "PlayerChaptersExpanded"
    class func playerChaptersExpanded() -> Bool {
        if let expanded = UserDefaults.standard.value(forKey: playerChaptersExpandedKey) as? Bool {
            return expanded
        }

        return true
    }

    class func setPlayerChaptersExpanded(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: playerChaptersExpandedKey)
    }

    // MARK: Subscription Cancelled Acknowledgement

    private static let subscriptionCancelledAcknowledgedKey = "SJCancelledAcknowledged"
    class func setSubscriptionCancelledAcknowledged(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: subscriptionCancelledAcknowledgedKey)
    }

    class func subscriptionCancelledAcknowledged() -> Bool {
        UserDefaults.standard.bool(forKey: subscriptionCancelledAcknowledgedKey)
    }

    // MARK: Promotion Finished Acknowledgement

    class func setPromotionFinishedAcknowledged(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.promotionFinishedAcknowledged)
    }

    class func promotionFinishedAcknowledged() -> Bool {
        UserDefaults.standard.bool(forKey: Constants.UserDefaults.promotionFinishedAcknowledged)
    }

    // MARK: Plus Info Closed

    private static let plusInfoFilesSettingsClosedKey = "PlusInfoClosedFileSettings"
    class func plusInfoDismissedOnFilesSettings() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.plusInfoFilesSettingsClosedKey)
    }

    class func setPlusInfoDismissedOnFilesSettings(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Settings.plusInfoFilesSettingsClosedKey)
    }

    private static let plusInfoFilesAddClosedKey = "PlusInfoClosedFileAdd"
    class func plusInfoDismissedOnFilesAdd() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.plusInfoFilesAddClosedKey)
    }

    class func setPlusInfoDismissedOnFilesAdd(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Settings.plusInfoFilesAddClosedKey)
    }

    private static let plusInfoAppearanceClosedKey = "PlusInfoClosedAppearance"
    class func plusInfoDismissedOnAppearance() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.plusInfoAppearanceClosedKey)
    }

    class func setPlusInfoDismissedOnAppearance(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Settings.plusInfoAppearanceClosedKey)
    }

    private static let plusInfoWatchClosedKey = "PlusInfoClosedWatch"
    class func plusInfoDismissedOnWatch() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.plusInfoWatchClosedKey)
    }

    class func setPlusInfoDismissedOnWatch(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Settings.plusInfoWatchClosedKey)
    }

    private static let plusInfoProfileClosedKey = "PlusInfoClosedProfile"
    class func plusInfoDismissedOnProfile() -> Bool {
        UserDefaults.standard.bool(forKey: Settings.plusInfoProfileClosedKey)
    }

    class func setPlusInfoDismissedOnProfile(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Settings.plusInfoProfileClosedKey)
    }

    class func uniqueAppId() -> String? {
        if let appId = UserDefaults.standard.object(forKey: Constants.UserDefaults.appId) as? String {
            return appId
        }

        return nil
    }

    // MARK: What's new

    private static let whatsNewLastAcknowledgedKey = "SJWhatsNewLastAcknowledged"

    class func setWhatsNewLastAcknowledged(_ value: Int) {
        UserDefaults.standard.set(value, forKey: whatsNewLastAcknowledgedKey)
    }

    class func whatsNewLastAcknowledged() -> Int {
        UserDefaults.standard.integer(forKey: whatsNewLastAcknowledgedKey)
    }


    private static let lastWhatsNewShownKey = "LastWhatsNewShown"
    class var lastWhatsNewShown: String? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: lastWhatsNewShownKey)
            UserDefaults.standard.synchronize()
        }

        get {
            UserDefaults.standard.string(forKey: lastWhatsNewShownKey)
        }
    }

    class func setShouldFollowSystemTheme(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.shouldFollowSystemThemeKey)
    }

    class func shouldFollowSystemTheme() -> Bool {
        UserDefaults.standard.bool(forKey: Constants.UserDefaults.shouldFollowSystemThemeKey)
    }

    // MARK: Player Actions

    private static let playerActionsKey = "PlayerActions"
    class func playerActions() -> [PlayerAction] {
        let defaultActions = PlayerAction.defaultActions.filter { $0.isAvailable }

        guard let savedInts = UserDefaults.standard.object(forKey: Settings.playerActionsKey) as? [Int] else {
            return defaultActions
        }

        let playerActions = savedInts
            .compactMap { PlayerAction(rawValue: $0) }
            .filter { $0.isAvailable }

        return playerActions + defaultActions.filter { !playerActions.contains($0) }
    }

    class func updatePlayerActions(_ actions: [PlayerAction]) {
        let actionInts = actions.map(\.rawValue)
        UserDefaults.standard.set(actionInts, forKey: Settings.playerActionsKey)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playerActionsUpdated)
    }

    // MARK: Multi Select Gesture

    private static let multiSelectGestureKey = "MultiSelectGestureEnabled"
    class func multiSelectGestureEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: multiSelectGestureKey)
    }

    class func setMultiSelectGestureEnabled(_ enabled: Bool, userInitiated: Bool = false) {
        UserDefaults.standard.set(enabled, forKey: multiSelectGestureKey)

        guard userInitiated else { return }
        Settings.trackValueToggled(.settingsGeneralMultiSelectGestureToggled, enabled: enabled)
    }

    // MARK: Multi Select Actions

    private static let multiSelectActionsKey = "MultiSelectActions"
    class func multiSelectActions() -> [MultiSelectAction] {
        let defaultActions: [MultiSelectAction] = [.playNext, .playLast, .download, .archive, .share, .markAsPlayed, .star]
        guard let savedInts = UserDefaults.standard.object(forKey: Settings.multiSelectActionsKey) as? [Int32] else {
            return defaultActions
        }

        let actions = savedInts.compactMap { MultiSelectAction(rawValue: $0) }

        // Make sure new items are shown
        return actions + defaultActions.filter { !actions.contains($0) }
    }

    class func updateMultiSelectActions(_ actions: [MultiSelectAction]) {
        let actionInts = actions.map(\.rawValue)
        UserDefaults.standard.set(actionInts, forKey: Settings.multiSelectActionsKey)
    }

    private static let filesMultiSelectActionsKey = "FilesMultiSelectActionsV2"
    class func fileMultiSelectActions() -> [MultiSelectAction] {
        guard let savedInts = UserDefaults.standard.object(forKey: Settings.filesMultiSelectActionsKey) as? [Int32] else {
            return [.playNext, .playLast, .download, .markAsPlayed, .delete]
        }

        let actions = savedInts.compactMap { MultiSelectAction(rawValue: $0) }

        return actions
    }

    class func updateFilesMultiSelectActions(_ actions: [MultiSelectAction]) {
        let actionInts = actions.map(\.rawValue)
        UserDefaults.standard.set(actionInts, forKey: Settings.filesMultiSelectActionsKey)
    }

    private static let upNextMultiSelectActionsKey = "UpNextMultiSelectActions"
    class func upNextMultiSelectActions() -> [MultiSelectAction] {
        guard let savedInts = UserDefaults.standard.object(forKey: Settings.upNextMultiSelectActionsKey) as? [Int32] else {
            return [.moveToTop, .moveToBottom, .removeFromUpNext, .download, .markAsPlayed, .archive]
        }

        let actions = savedInts.compactMap { MultiSelectAction(rawValue: $0) }

        return actions
    }

    class func updateUpNextMultiSelectActions(_ actions: [MultiSelectAction]) {
        let actionInts = actions.map(\.rawValue)
        UserDefaults.standard.set(actionInts, forKey: Settings.upNextMultiSelectActionsKey)
    }

    // MARK: - Password changed and watch requires update

    class func loginDetailsUpdated() -> Bool {
        UserDefaults.standard.bool(forKey: Constants.UserDefaults.loginDetailsUpdated)
    }

    class func clearLoginDetailsUpdated() {
        UserDefaults.standard.set(false, forKey: Constants.UserDefaults.loginDetailsUpdated)
    }

    class func setLoginDetailsUpdated() {
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.loginDetailsUpdated)
    }

    // MARK: - Watch number of episodes to auto sync from the Up Next queue

    class func setWatchAutoDownloadUpNextEnabled(isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: Constants.UserDefaults.watchAutoDownloadUpNextEnabled)

        trackValueToggled(.settingsAppleWatchAutoDownloadUpNextToggled, enabled: isEnabled)
    }

    class func watchAutoDownloadUpNextEnabled() -> Bool {
        guard let isEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaults.watchAutoDownloadUpNextEnabled) as? Bool else {
            return false
        }

        return isEnabled
    }

    class func setWatchAutoDownloadUpNextCount(numEpisodes: Int) {
        UserDefaults.standard.set(numEpisodes, forKey: Constants.UserDefaults.watchAutoDownloadUpNextCount)
        trackValueChanged(.settingsAppleWatchAutoDownloadEpisodesChanged, value: numEpisodes)
    }

    class func watchAutoDownloadUpNextCount() -> Int {
        guard let numEpisodes = UserDefaults.standard.object(forKey: Constants.UserDefaults.watchAutoDownloadUpNextCount) as? Int else {
            return 3
        }

        return numEpisodes
    }

    class func setWatchAutoDeleteUpNext(isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: Constants.UserDefaults.watchAutoDeleteUpNext)
        trackValueToggled(.settingsAppleWatchAutoDownloadDeleteDownloadsToggled, enabled: isEnabled)
    }

    class func watchAutoDeleteUpNext() -> Bool {
        guard let isEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaults.watchAutoDeleteUpNext) as? Bool else {
            return true
        }

        return isEnabled
    }

    // MARK: - App Store Review Requests

    class func addReviewRequested() {
        var reviewRequestDates = Self.reviewRequestDates()
        reviewRequestDates.append(Date())
        UserDefaults.standard.set(reviewRequestDates, forKey: Constants.UserDefaults.reviewRequestDates)
    }

    class func reviewRequestDates() -> [Date] {
        UserDefaults.standard.array(forKey: Constants.UserDefaults.reviewRequestDates) as? [Date] ?? [Date]()
    }

    // MARK: - Tracks

    class func setAnalytics(optOut: Bool) {
        UserDefaults.standard.set(optOut, forKey: Constants.UserDefaults.analyticsOptOut)
    }

    class func analyticsOptOut() -> Bool {
        UserDefaults.standard.bool(forKey: Constants.UserDefaults.analyticsOptOut)
    }

    // MARK: - End of Year 2022

    class var showBadgeForEndOfYear: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.showBadgeFor2023EndOfYear)
        }

        get {
            (UserDefaults.standard.value(forKey: Constants.UserDefaults.showBadgeFor2023EndOfYear) as? Bool) ?? true
        }
    }

    class var endOfYearModalHasBeenShown: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.modal2023HasBeenShown)
        }

        get {
            UserDefaults.standard.bool(forKey: Constants.UserDefaults.modal2023HasBeenShown)
        }
    }

    class var hasSyncedEpisodesForPlayback2023: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.hasSyncedEpisodesForPlayback2023)
        }

        get {
            UserDefaults.standard.bool(forKey: Constants.UserDefaults.hasSyncedEpisodesForPlayback2023)
        }
    }

    /// Whether the user was plus or not by the time the sync happened
    class var hasSyncedEpisodesForPlayback2023AsPlusUser: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.hasSyncedEpisodesForPlayback2023AsPlusUser)
        }

        get {
            UserDefaults.standard.bool(forKey: Constants.UserDefaults.hasSyncedEpisodesForPlayback2023AsPlusUser)
        }
    }

    class var top5PodcastsListLink: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.top5PodcastsListLink)
        }

        get {
            UserDefaults.standard.string(forKey: Constants.UserDefaults.top5PodcastsListLink)
        }
    }

    static var shouldShowInitialOnboardingFlow: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.shouldShowInitialOnboardingFlow)
        }
        get {
            UserDefaults.standard.bool(forKey: Constants.UserDefaults.shouldShowInitialOnboardingFlow)
        }
    }

    static var hasSeenInitialOnboardingBefore: Bool {
        get {
            UserDefaults.standard.object(forKey: Constants.UserDefaults.shouldShowInitialOnboardingFlow) != nil
        }
    }

    // MARK: - Embedded Artwork

    static var loadEmbeddedImages: Bool {
        get {
            UserDefaults.standard.bool(forKey: Constants.UserDefaults.loadEmbeddedImages)
        }
    }

    // MARK: - Autoplay

    static var autoplay: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaults.autoplay)
        }
        get {
            UserDefaults.standard.bool(forKey: Constants.UserDefaults.autoplay)
        }
    }


    // MARK: - Headphone Controls

    static var headphonesPreviousAction: HeadphoneControlAction {
        get {
            Constants.UserDefaults.headphones.previousAction.unlockedValue
        }

        set {
            Constants.UserDefaults.headphones.previousAction.save(newValue)
        }
    }

    static var headphonesNextAction: HeadphoneControlAction {
        get {
            Constants.UserDefaults.headphones.nextAction.unlockedValue
        }

        set {
            Constants.UserDefaults.headphones.nextAction.save(newValue)
        }
    }


    /// Returns whether the bookmark creation sound option is enabled
    static var isPlayBookmarkCreationSoundAvailable: Bool {
        [Settings.headphonesNextAction, Settings.headphonesPreviousAction].contains(.addBookmark)
    }

    /// Determines if we should play the sound when a bookmark is created
    static var shouldPlayBookmarkSound: Bool {
        isPlayBookmarkCreationSoundAvailable && playBookmarkCreationSound
    }

    static var playBookmarkCreationSound: Bool {
        get {
            Constants.UserDefaults.bookmarks.creationSound.value
        }

        set {
            Constants.UserDefaults.bookmarks.creationSound.save(newValue)
        }
    }

    static var darkUpNextTheme: Bool {
        get {
            Constants.UserDefaults.appearance.darkUpNextTheme.value
        }

        set {
            Constants.UserDefaults.appearance.darkUpNextTheme.save(newValue)
        }
    }

    static var skipBackTime: Int {
        get {
            if FeatureFlag.settingsSync.enabled {
                return Int(SettingsStore.appSettings.skipBack)
            } else {
                return ServerSettings.skipBackTime()
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                SettingsStore.appSettings.skipBack = Int32(newValue)
            }
            ServerSettings.setSkipBackTime(newValue)
        }
    }

    static var skipForwardTime: Int {
        get {
            if FeatureFlag.settingsSync.enabled {
                return Int(SettingsStore.appSettings.skipForward)
            } else {
                return ServerSettings.skipForwardTime()
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                SettingsStore.appSettings.skipForward = Int32(newValue)
            }
            ServerSettings.setSkipForwardTime(newValue)
        }
    }

    // MARK: - Variables that are loaded/changed through Firebase

    #if !os(watchOS)
        class func minTimeBetweenProgressSaves() -> TimeInterval {
            remoteMsToTime(key: Constants.RemoteParams.periodicSaveTimeMs)
        }

        class func podcastSearchDebounceTime() -> TimeInterval {
            remoteMsToTime(key: Constants.RemoteParams.podcastSearchDebounceMs)
        }

        class func episodeSearchDebounceTime() -> TimeInterval {
            remoteMsToTime(key: Constants.RemoteParams.episodeSearchDebounceMs)
        }

        static var endOfYearRequireAccount: Bool {
            let remote = RemoteConfig.remoteConfig().configValue(forKey: Constants.RemoteParams.endOfYearRequireAccount)
            return remote.boolValue
        }

        static var addMissingEpisodes: Bool {
            let remote = RemoteConfig.remoteConfig().configValue(forKey: Constants.RemoteParams.addMissingEpisodes)
            return remote.boolValue
        }

        static var newPlayerTransition: Bool {
            let remote = RemoteConfig.remoteConfig().configValue(forKey: Constants.RemoteParams.newPlayerTransition)
            return remote.boolValue
        }

        static var effectsPlayerStrategy: EffectsPlayerStrategy? {
            let remote = RemoteConfig.remoteConfig().configValue(forKey: Constants.RemoteParams.effectsPlayerStrategy)
            return EffectsPlayerStrategy(rawValue: remote.numberValue.intValue)
        }

        static var plusCloudStorageLimit: Int {
            RemoteConfig.remoteConfig().configValue(forKey: Constants.RemoteParams.customStorageLimitGB).numberValue.intValue
        }

        static var patronCloudStorageLimit: Int {
            RemoteConfig.remoteConfig().configValue(forKey: Constants.RemoteParams.patronCloudStorageGB).numberValue.intValue
        }

        static var errorLogoutHandling: Bool {
            return RemoteConfig.remoteConfig().configValue(forKey: Constants.RemoteParams.errorLogoutHandling).boolValue
        }

        private class func remoteMsToTime(key: String) -> TimeInterval {
            let remoteMs = RemoteConfig.remoteConfig().configValue(forKey: key)

            return TimeInterval(remoteMs.numberValue.doubleValue / 1000)
        }
    #endif
}

extension Settings {
    static func trackValueChanged(_ event: AnalyticsEvent, value: Any) {
        Analytics.track(event, properties: ["value": value])
    }

    static func trackValueToggled(_ event: AnalyticsEvent, enabled: Bool) {
        Analytics.track(event, properties: ["enabled": enabled])
    }
}

#if !os(watchOS)
extension L10n {
    static var plusCloudStorageLimit: String {
        plusCloudStorageLimitFormat(Settings.plusCloudStorageLimit.localized())
    }

    static var patronCloudStorageLimit: String {
        plusCloudStorageLimitFormat(Settings.patronCloudStorageLimit.localized())
    }
}
#endif
