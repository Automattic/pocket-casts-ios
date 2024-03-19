import PocketCastsDataModel
import PocketCastsUtils

extension DataManager {
    func importPodcastSettings() {
        let podcasts = allPodcasts(includeUnsubscribed: true)

        podcasts.forEach { podcast in
            podcast.settings.$autoStartFrom = ModifiedDate<Int32>(wrappedValue: podcast.startFrom)
            podcast.settings.$autoSkipLast = ModifiedDate<Int32>(wrappedValue: podcast.skipLast)
            podcast.settings.$playbackSpeed = ModifiedDate<Double>(wrappedValue: podcast.playbackSpeed)
            podcast.settings.$showArchived = ModifiedDate<Bool>(wrappedValue: podcast.showArchived)
            if let trimSilence = TrimSilenceAmount(rawValue: podcast.trimSilenceAmount) {
                podcast.settings.$trimSilence = ModifiedDate<TrimSilence>(wrappedValue: TrimSilence(amount: trimSilence))
            }
            podcast.settings.$boostVolume = ModifiedDate<Bool>(wrappedValue: podcast.boostVolume)
            podcast.settings.$notification = ModifiedDate<Bool>(wrappedValue: podcast.pushEnabled)
            if let oldValue = PodcastEpisodeSortOrder.Old(rawValue: podcast.episodeSortOrder) {
                let episodeSortOrder = PodcastEpisodeSortOrder(old: oldValue)
                podcast.settings.$episodesSortOrder = ModifiedDate<PodcastEpisodeSortOrder>(wrappedValue: episodeSortOrder)
			}
            if let grouping = PodcastGrouping(rawValue: podcast.episodeGrouping) {
                podcast.settings.$episodeGrouping = ModifiedDate<PodcastGrouping>(wrappedValue: grouping)
            }
            podcast.settings.$autoArchive = ModifiedDate<Bool>(wrappedValue: podcast.overrideGlobalArchive)
            if let archiveTime = AutoArchiveAfterTime(rawValue: podcast.autoArchivePlayedAfter), let archivePlayed = AutoArchiveAfterPlayed(time: archiveTime) {
                podcast.settings.$autoArchivePlayed = ModifiedDate<AutoArchiveAfterPlayed>(wrappedValue: archivePlayed)
            }
            if let archiveTime = AutoArchiveAfterTime(rawValue: podcast.autoArchiveInactiveAfter), let archiveInactive = AutoArchiveAfterInactive(time: archiveTime) {
                podcast.settings.$autoArchiveInactive = ModifiedDate<AutoArchiveAfterInactive>(wrappedValue: archiveInactive)
            }

            if let setting = AutoAddToUpNextSetting(rawValue: podcast.autoAddToUpNext) {
                podcast.settings.autoUpNextSetting = setting
            }

            save(podcast: podcast)
        }
    }
}
