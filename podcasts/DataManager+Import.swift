import PocketCastsDataModel
import PocketCastsUtils

extension DataManager {
    func importPodcastSettings() {
        let podcasts = allPodcasts(includeUnsubscribed: true)

        let date = Date.syncDefaultDate
        podcasts.enumerated().forEach { (idx, podcast) in
            podcast.settings.$autoStartFrom = ModifiedDate<Int32>(wrappedValue: podcast.startFrom, modifiedAt: date)
            podcast.settings.$autoSkipLast = ModifiedDate<Int32>(wrappedValue: podcast.skipLast, modifiedAt: date)
            podcast.settings.$playbackSpeed = ModifiedDate<Double>(wrappedValue: podcast.playbackSpeed, modifiedAt: date)
            podcast.settings.$showArchived = ModifiedDate<Bool>(wrappedValue: podcast.showArchived, modifiedAt: date)
            podcast.settings.$customEffects = ModifiedDate<Bool>(wrappedValue: podcast.overrideGlobalEffects, modifiedAt: date)
            if let trimSilence = TrimSilenceAmount(rawValue: podcast.trimSilenceAmount) {
                podcast.settings.$trimSilence = ModifiedDate<TrimSilence>(wrappedValue: TrimSilence(amount: trimSilence), modifiedAt: date)
            }
            podcast.settings.$boostVolume = ModifiedDate<Bool>(wrappedValue: podcast.boostVolume, modifiedAt: date)
            podcast.settings.$notification = ModifiedDate<Bool>(wrappedValue: podcast.pushEnabled, modifiedAt: date)
            if let oldValue = PodcastEpisodeSortOrder.Old(rawValue: podcast.episodeSortOrder) {
                let episodeSortOrder = PodcastEpisodeSortOrder(old: oldValue)
                podcast.settings.$episodesSortOrder = ModifiedDate<PodcastEpisodeSortOrder>(wrappedValue: episodeSortOrder, modifiedAt: date)
			}
            if let grouping = PodcastGrouping(rawValue: podcast.episodeGrouping) {
                podcast.settings.$episodeGrouping = ModifiedDate<PodcastGrouping>(wrappedValue: grouping, modifiedAt: date)
            }
            podcast.settings.$autoArchive = ModifiedDate<Bool>(wrappedValue: podcast.overrideGlobalArchive, modifiedAt: date)
            if let archiveTime = AutoArchiveAfterTime(rawValue: podcast.autoArchivePlayedAfter), let archivePlayed = AutoArchiveAfterPlayed(time: archiveTime) {
                podcast.settings.$autoArchivePlayed = ModifiedDate<AutoArchiveAfterPlayed>(wrappedValue: archivePlayed, modifiedAt: date)
            }
            podcast.settings.autoArchiveEpisodeLimit = podcast.autoArchiveEpisodeLimit
            if let archiveTime = AutoArchiveAfterTime(rawValue: podcast.autoArchiveInactiveAfter), let archiveInactive = AutoArchiveAfterInactive(time: archiveTime) {
                podcast.settings.$autoArchiveInactive =  ModifiedDate<AutoArchiveAfterInactive>(wrappedValue: archiveInactive, modifiedAt: date)
            }

            if let setting = AutoAddToUpNextSetting(rawValue: podcast.autoAddToUpNext) {
                podcast.settings.$addToUpNext = ModifiedDate<Bool>(wrappedValue: setting.enabled, modifiedAt: date)
                if let position = setting.position {
                    podcast.settings.$addToUpNextPosition = ModifiedDate<UpNextPosition>(wrappedValue: position, modifiedAt: date)
                }
            }

            podcast.syncStatus = SyncStatus.notSynced.rawValue
            save(podcast: podcast, cache: idx == podcasts.endIndex)
        }
    }
}
