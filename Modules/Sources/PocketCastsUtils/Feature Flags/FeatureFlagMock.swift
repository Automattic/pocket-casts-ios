internal class FeatureFlagMock {
    private var previousValues: [FeatureFlag: Bool] = [:]

    func set(_ featureFlag: FeatureFlag, value: Bool) {
        do {
            previousValues[featureFlag] = featureFlag.enabled

            try FeatureFlagOverrideStore().override(featureFlag, withValue: value)
        } catch { }
    }

    func reset() {
        previousValues.forEach { flag in
            set(flag.key, value: flag.value)
        }

        previousValues = [:]
    }
}
