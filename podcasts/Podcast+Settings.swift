import PocketCastsDataModel

extension Podcast {
    var isEffectsOverridden: Bool {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.customEffects
            } else {
                return overrideGlobalEffects
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                settings.customEffects = newValue
            } else {
                overrideGlobalEffects = newValue
            }
        }
    }

    var autoStartFrom: Int32 {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.autoStartFrom
            } else {
                return startFrom
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                settings.autoStartFrom = newValue
            }
            startFrom = newValue
        }
    }

    var autoSkipLast: Int32 {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.autoSkipLast
            } else {
                return skipLast
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                settings.autoSkipLast = newValue
            }
            skipLast = newValue
        }
    }
}
