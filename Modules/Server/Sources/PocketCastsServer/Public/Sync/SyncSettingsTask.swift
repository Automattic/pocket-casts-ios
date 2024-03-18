import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

extension Api_ChangeableSettings {
    mutating func update(with settings: AppSettings) {
        let oldSettings = self
        openLinks.update(settings.$openLinks)
        rowActionGlobal.update(settings.$rowAction)
        skipForward.update(settings.$skipForward)
        skipBack.update(settings.$skipBack)
        keepScreenAwake.update(settings.$keepScreenAwake)
        openPlayer.update(settings.$openPlayer)
        intelligentResumption.update(settings.$intelligentResumption)
        episodeGrouping.update(settings.$episodeGrouping)
        showArchived.update(settings.$showArchived)
        upNextSwipe.update(settings.$upNextSwipe)
        playUpNextOnTap.update(settings.$playUpNextOnTap)
        playbackActions.update(settings.$playbackActions)
        legacyBluetooth.update(settings.$legacyBluetooth)
        multiSelectGesture.update(settings.$multiSelectGesture)
        chapterTitles.update(settings.$chapterTitles)
        autoPlayEnabled.update(settings.$autoPlayEnabled)
        notifications.update(settings.$notifications)
        volumeBoostGlobal.update(settings.$volumeBoost)
        trimSilence.update(settings.$trimSilence)
        playbackSpeed.update(settings.$playbackSpeed)
        warnDataUsage.update(settings.$warnDataUsage)
        playerBookmarksSortType.update(settings.$playerBookmarksSortType)
        episodeBookmarksSortType.update(settings.$episodeBookmarksSortType)
        podcastBookmarksSortType.update(settings.$podcastBookmarksSortType)
        bookmarksSortOrder.update(settings.$profileBookmarksSortType)
        headphoneControlsNextAction.update(settings.$headphoneControlsNextAction)
        headphoneControlsPreviousAction.update(settings.$headphoneControlsPreviousAction)
        privacyAnalytics.update(settings.$privacyAnalytics)
        marketingOptIn.update(settings.$marketingOptIn)
        freeGiftAcknowledgement.update(settings.$freeGiftAcknowledgement)
        autoArchivePlayed.update(settings.$autoArchivePlayed)
        autoArchiveInactive.update(settings.$autoArchiveInactive)
        autoArchiveIncludesStarredGlobal.update(settings.$autoArchiveIncludesStarred)
        gridOrder.update(settings.$gridOrder)
        gridLayoutGlobal.update(settings.$gridLayout)
        badgesGlobal.update(settings.$badges)
        filesAutoUpNextGlobal.update(settings.$filesAutoUpNext)
        filesAfterPlayingDeleteLocalGlobal.update(settings.$filesAfterPlayingDeleteLocal)
        filesAfterPlayingDeleteCloudGlobal.update(settings.$filesAfterPlayingDeleteCloud)
        playerShelfGlobal.update(settings.$playerShelf)
        useEmbeddedArtworkGlobal.update(settings.$useEmbeddedArtwork)
        theme.update(settings.$theme)
        useSystemTheme.update(settings.$useSystemTheme)
        lightThemePreference.update(settings.$lightThemePreference)
        darkThemePreference.update(settings.$darkThemePreference)
        useDarkUpNextTheme.update(settings.$useDarkUpNextTheme)
        autoUpNextLimit.update(settings.$autoUpNextLimit)
        autoUpNextLimitReached.update(settings.$autoUpNextLimitReached)
    }
}

extension AppSettings {
    mutating func update(with settings: Api_NamedSettingsResponse) {
        let oldSettings = self
        $openLinks.update(setting: settings.openLinks)
        $rowAction.update(setting: settings.rowActionGlobal)
        $skipForward.update(setting: settings.skipForward)
        $skipBack.update(setting: settings.skipBack)
        $keepScreenAwake.update(setting: settings.keepScreenAwake)
        $openPlayer.update(setting: settings.openPlayer)
        $intelligentResumption.update(setting: settings.intelligentResumption)
        $episodeGrouping.update(setting: settings.episodeGrouping)
        $showArchived.update(setting: settings.showArchived)
        $upNextSwipe.update(setting: settings.upNextSwipe)
        $playUpNextOnTap.update(setting: settings.playUpNextOnTap)
        $playbackActions.update(setting: settings.playbackActions)
        $legacyBluetooth.update(setting: settings.legacyBluetooth)
        $multiSelectGesture.update(setting: settings.multiSelectGesture)
        $chapterTitles.update(setting: settings.chapterTitles)
        $autoPlayEnabled.update(setting: settings.autoPlayEnabled)
        $notifications.update(setting: settings.notifications)
        $volumeBoost.update(setting: settings.volumeBoostGlobal)
        $trimSilence.update(setting: settings.trimSilence)
        $playbackSpeed.update(setting: settings.playbackSpeed)
        $warnDataUsage.update(setting: settings.warnDataUsage)
        $playerBookmarksSortType.update(setting: settings.playerBookmarksSortType)
        $episodeBookmarksSortType.update(setting: settings.episodeBookmarksSortType)
        $podcastBookmarksSortType.update(setting: settings.podcastBookmarksSortType)
        $profileBookmarksSortType.update(setting: settings.bookmarksSortOrder)
        $headphoneControlsNextAction.update(setting: settings.headphoneControlsNextAction)
        $headphoneControlsPreviousAction.update(setting: settings.headphoneControlsPreviousAction)
        $privacyAnalytics.update(setting: settings.privacyAnalytics)
        $marketingOptIn.update(setting: settings.marketingOptIn)
        $freeGiftAcknowledgement.update(setting: settings.freeGiftAcknowledgement)
        $autoArchivePlayed.update(setting: settings.autoArchivePlayed)
        $autoArchiveInactive.update(setting: settings.autoArchiveInactive)
        $autoArchiveIncludesStarred.update(setting: settings.autoArchiveIncludesStarredGlobal)
        $gridOrder.update(setting: settings.gridOrder)
        $gridLayout.update(setting: settings.gridLayoutGlobal)
        $badges.update(setting: settings.badgesGlobal)
        $filesAutoUpNext.update(setting: settings.filesAutoUpNextGlobal)
        $filesAfterPlayingDeleteLocal.update(setting: settings.filesAfterPlayingDeleteLocalGlobal)
        $filesAfterPlayingDeleteCloud.update(setting: settings.filesAfterPlayingDeleteCloudGlobal)
        $playerShelf.update(setting: settings.playerShelfGlobal)
        $useEmbeddedArtwork.update(setting: settings.useEmbeddedArtworkGlobal)
        $theme.update(setting: settings.theme)
        $useSystemTheme.update(setting: settings.useSystemTheme)
        $lightThemePreference.update(setting: settings.lightThemePreference)
        $darkThemePreference.update(setting: settings.darkThemePreference)
        $useDarkUpNextTheme.update(setting: settings.useDarkUpNextTheme)
        $autoUpNextLimit.update(setting: settings.autoUpNextLimit)
        $autoUpNextLimitReached.update(setting: settings.autoUpNextLimitReached)
        oldSettings.printDiff(from: self)
    }
}

class SyncSettingsTask: ApiBaseTask {

    private let appSettings: SettingsStore<AppSettings>

    init(appSettings: SettingsStore<AppSettings> = SettingsStore.appSettings, dataManager: DataManager = .sharedManager, urlConnection: URLConnection = URLConnection(handler: URLSession.shared)) {
        self.appSettings = appSettings
        super.init(dataManager: dataManager, urlConnection: urlConnection)
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/named_settings/update"
        do {
            var settingsRequest = Api_NamedSettingsRequest()
            settingsRequest.m = "iPhone"

            if FeatureFlag.settingsSync.enabled {
                settingsRequest.changedSettings.update(with: appSettings.settings)
                FileLog.shared.addMessage("Syncing new settings: \(try! settingsRequest.changedSettings.jsonString())")
            } else {
                if ServerSettings.skipBackNeedsSyncing() {
                    settingsRequest.settings.skipBack.value = Int32(ServerSettings.skipBackTime())
                }
                if ServerSettings.skipForwardNeedsSyncing() {
                    settingsRequest.settings.skipForward.value = Int32(ServerSettings.skipForwardTime())
                }
                if ServerSettings.marketingOptInNeedsSyncing() {
                    settingsRequest.settings.marketingOptIn.value = ServerSettings.marketingOptIn()
                }
                if SubscriptionHelper.subscriptionGiftAcknowledgementNeedsSyncing() {
                    settingsRequest.settings.freeGiftAcknowledgement.value = SubscriptionHelper.subscriptionGiftAcknowledgement()
                }
                if ServerSettings.homeGridSortOrderNeedsSyncing() {
                    settingsRequest.settings.gridOrder.value = ServerConverter.convertToServerSortType(clientType: ServerSettings.homeGridSortOrder())
                }
            }

            let data = try settingsRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            if let response = response, httpStatus == ServerConstants.HttpConstants.ok {
                process(serverData: response)
            } else {
                FileLog.shared.addMessage("SyncSettingsTask Unable to sync with server got status \(httpStatus)")
            }
        } catch {
            FileLog.shared.addMessage("SyncSettingsTask Protobuf Encoding failed")
        }
    }

    private func process(serverData: Data) {
        do {
            let settings = try Api_NamedSettingsResponse(serializedData: serverData)

            if FeatureFlag.settingsSync.enabled {
                appSettings.settings.update(with: settings)
            } else {
                if settings.skipForward.changed.value {
                    let skipForwardTime = Int(settings.skipForward.value.value)
                    if skipForwardTime > 0, skipForwardTime != ServerSettings.skipForwardTime() {
                        ServerSettings.setSkipForwardTime(skipForwardTime, syncChange: false)
                    }
                }

                if settings.skipBack.changed.value {
                    let skipBackTime = Int(settings.skipBack.value.value)
                    if skipBackTime > 0, skipBackTime != ServerSettings.skipBackTime() {
                        ServerSettings.setSkipBackTime(skipBackTime, syncChange: false)
                    }
                }

                if settings.marketingOptIn.changed.value {
                    let marketingOptIn = settings.marketingOptIn.value.value
                    ServerSettings.setMarketingOptIn(marketingOptIn)
                }

                if settings.freeGiftAcknowledgement.changed.value {
                    let acknowledgement = settings.freeGiftAcknowledgement.value.value
                    SubscriptionHelper.setSubscriptionGiftAcknowledgement(acknowledgement)
                }
                if settings.gridOrder.changed.value {
                    let newOrder = ServerConverter.convertToClientSortType(serverType: settings.gridOrder.value.value)
                    ServerSettings.setHomeGridSortOrder(newOrder, syncChange: false)
                }
            }

            ServerSettings.setSkipBackSynced()
            ServerSettings.setSkipForwardSynced()
            ServerSettings.marketingOptInSynced()
            ServerSettings.setHomeGridSortOrderSynced()
            SubscriptionHelper.subscriptionGiftAcknowledgementSynced()
        } catch {
            FileLog.shared.addMessage("SyncSettingsTask decoding response failed \(error.localizedDescription)")
        }
    }
}
