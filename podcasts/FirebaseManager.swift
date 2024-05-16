import PocketCastsUtils
import FirebaseRemoteConfig

struct FirebaseManager {
    static func refreshRemoteConfig(expirationDuration: TimeInterval = 2.hour, completion: ((RemoteConfigFetchStatus) -> Void)? = nil) {
        // we user remote config for varies parameters in the app we want to be able to set remotely. Here we set the defaults, then fetch new ones
        let remoteConfig = RemoteConfig.remoteConfig()
        var remoteConfigDefaults = [
            Constants.RemoteParams.periodicSaveTimeMs: NSNumber(value: Constants.RemoteParams.periodicSaveTimeMsDefault),
            Constants.RemoteParams.episodeSearchDebounceMs: NSNumber(value: Constants.RemoteParams.episodeSearchDebounceMsDefault),
            Constants.RemoteParams.podcastSearchDebounceMs: NSNumber(value: Constants.RemoteParams.podcastSearchDebounceMsDefault),
            Constants.RemoteParams.customStorageLimitGB: NSNumber(value: Constants.RemoteParams.customStorageLimitGBDefault),
            Constants.RemoteParams.endOfYearRequireAccount: NSNumber(value: Constants.RemoteParams.endOfYearRequireAccountDefault),
            Constants.RemoteParams.effectsPlayerStrategy: NSNumber(value: Constants.RemoteParams.effectsPlayerStrategyDefault),
            Constants.RemoteParams.patronCloudStorageGB: NSNumber(value: Constants.RemoteParams.patronCloudStorageGBDefault),
            Constants.RemoteParams.addMissingEpisodes: NSNumber(value: Constants.RemoteParams.addMissingEpisodesDefault),
            Constants.RemoteParams.newPlayerTransition: NSNumber(value: Constants.RemoteParams.newPlayerTransitionDefault),
            Constants.RemoteParams.errorLogoutHandling: NSNumber(value: Constants.RemoteParams.errorLogoutHandlingDefault),
            Constants.RemoteParams.slumberStudiosPromoCode: NSString(string: Constants.RemoteParams.slumberStudiosPromoCodeDefault)
        ]
        FeatureFlag.allCases.filter { $0.remoteKey != nil }.forEach { flag in
            remoteConfigDefaults[flag.remoteKey!] = NSNumber(value: flag.default)
        }
        remoteConfig.setDefaults(remoteConfigDefaults)

        remoteConfig.fetch(withExpirationDuration: expirationDuration) { status, _ in
            if status == .success {
                remoteConfig.activate(completion: nil)
            }
            completion?(status)
        }
    }
}
