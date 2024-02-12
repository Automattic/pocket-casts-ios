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
}
