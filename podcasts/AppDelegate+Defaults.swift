import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    func checkDefaults() {
        lazy var defaults = UserDefaults.standard
        lazy var dataManager = DataManager.sharedManager

        performUpdateIfRequired(updateKey: "v5Run") {
            // these are considered defaults for a new app install
            SyncManager.clearTokensFromKeyChain()
            ServerSettings.setSkipBackTime(10, syncChange: false)
            ServerSettings.setSkipForwardTime(45, syncChange: false)

            Settings.setShouldDeleteWhenPlayed(true)
            Settings.setHomeFolderSortOrder(order: .dateAddedNewestToOldest)
            Settings.setMobileDataAllowed(true)
            Settings.shouldShowInitialOnboardingFlow = true
            Settings.autoplay = true

            // Disable dark up next theme for new users
            Settings.darkUpNextTheme = false

            setWhatsNewAcknowledgeToLatest()
        }

        performUpdateIfRequired(updateKey: "v6Run") {
            let query = "SELECT COUNT(*) FROM \(DataManager.podcastTableName) WHERE autoDownloadSetting == 1 AND subscribed == 1"
            let podcastsWithAutoDownloadOn = dataManager.count(query: query, values: nil)
            let autoDownloadEnabled = podcastsWithAutoDownloadOn > 0
            Settings.setAutoDownloadEnabled(autoDownloadEnabled)
        }

        performUpdateIfRequired(updateKey: "v6_5Run") {
            defaults.set(false, forKey: Constants.UserDefaults.cleanupUnplayed)
            defaults.set(false, forKey: Constants.UserDefaults.cleanupStarred)
            defaults.set(true, forKey: Constants.UserDefaults.cleanupInProgress)
            defaults.set(true, forKey: Constants.UserDefaults.cleanupPlayed)
        }

        performUpdateIfRequired(updateKey: "v7Run") {
            defaults.set(2, forKey: Constants.UserDefaults.lastTabOpened)
        }

        performUpdateIfRequired(updateKey: "v7bRun") {
            Settings.setAutoDownloadMobileDataAllowed(false)
        }

        performUpdateIfRequired(updateKey: "v7cRun") {
            Settings.setAutoArchivePlayedAfter(0)
            Settings.setAutoArchiveInactiveAfter(-1)
            Settings.setArchiveStarredEpisodes(false)
        }

        performUpdateIfRequired(updateKey: "v7_3Run") {
            ImageManager.sharedManager.upgradeV2ToV3ArtworkFolder()
            ServerSettings.setLastRefreshSucceeded(true)
            ServerSettings.setLastSyncSucceeded(true)
        }

        performUpdateIfRequired(updateKey: "TTFRunFinal") {
            ServerSettings.setUserEpisodeOnlyOnWifi(true)
        }

        performUpdateIfRequired(updateKey: "v7_11Run") {
            if let email = ServerSettings.syncingEmailLegacy() {
                FileLog.shared.addMessage("Migrating email address from preferences to Keychain")
                ServerSettings.setSyncingEmail(email: email)
                ServerSettings.removeLegacySyncingEmail()
            }
        }
        performUpdateIfRequired(updateKey: "v7_12Run") {
            Settings.setMultiSelectGestureEnabled(true)
        }
        performUpdateIfRequired(updateKey: "v7_15Run") {
            defaults.setValue(true, forKey: Constants.UserDefaults.intelligentPlaybackResumption)
        }
        performUpdateIfRequired(updateKey: "v7_16Run") {
            ServerSettings.setAutoAddToUpNextLimit(100)
        }
        performUpdateIfRequired(updateKey: "v7_19_1Run") {
            // we didn't previously need a default value for this key, but due to changes in this release we do, otherwise it will default to the first item in the ThemeType enum
            let preferredDarkTheme = Theme.preferredDarkTheme()
            if preferredDarkTheme.rawValue == 0 {
                Theme.setPreferredDarkTheme(.dark, systemIsDark: false)
            }
        }
        performUpdateIfRequired(updateKey: "FoldersInitialRun") {
            // here we are upgrading to folders, since it's possible we've already been syncing with the server and ignoring folder information, we'll need to re-request it
            if SyncManager.isUserLoggedIn() {
                ApiServerHandler.shared.reloadFoldersFromServer()
            }
        }

        // Clean up any Ghost episodes in users filters
        // https://github.com/Automattic/pocket-casts-ios/issues/135
        performUpdateIfRequired(updateKey: "v7_20_1_Ghost_Fix") {
            PodcastManager.shared.deleteGhostEpisodesIfNeeded()
        }

        // Check if we're missing the stored local userId and retrieve it if needed
        performUpdateIfRequired(updateKey: "MissingUserIdCheck") {
            retrieveUserIdIfNeeded()
        }

        performUpdateIfRequired(updateKey: "UpdateFileProtection") {
            Task {
                await DownloadManager.shared.updateProtectionPermissionsForAllExistingFiles()
            }
        }

        // With the addition of bookmarks we have added a new headphone controls setting that this is being migrated to
        // This will check if the user has the old Remote Skips Chapters preference enabled, and will move that setting
        // by setting both the previous and next track actions to the change chapter action.
        performUpdateIfRequired(updateKey: "MigrateRemoteSkipsChaptersToHeadphoneControls") {
            let key = "RemoteChapterSkip"

            if UserDefaults.standard.bool(forKey: key) {
                Settings.headphonesNextAction = .nextChapter
                Settings.headphonesPreviousAction = .previousChapter

                // Remove the setting
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        if FeatureFlag.newSettingsStorage.enabled {
            performUpdateIfRequired(updateKey: "MigrateToSyncedSettings") {
                SettingsStore.appSettings.importUserDefaults()
                DataManager.sharedManager.importPodcastSettings()
            }
        }

        defaults.synchronize()
    }

    private func performUpdateIfRequired(updateKey: String, update: () -> Void) {
        if UserDefaults.standard.bool(forKey: updateKey) { return } // already performed this update

        update()
        UserDefaults.standard.set(true, forKey: updateKey)
    }

    private func setWhatsNewAcknowledgeToLatest() {
        if let whatsNewInfo = WhatsNewHelper.extractWhatsNewInfo() {
            Settings.setWhatsNewLastAcknowledged(whatsNewInfo.versionCode)
        }
    }
}
