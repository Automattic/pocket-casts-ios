import Foundation

public extension Notification.Name {
    /// Posted when Remote Config turns a feature flag on or off.
    static let featureFlagsDidChange = Notification.Name("FeatureFlagsDidChange")
}

public extension FeatureFlag {
    /// Overrides every flag that has a remote key with its Remote Config value, and posts
    /// ``Foundation/Notification/Name/featureFlagsDidChange`` when that turns any flag on or off.
    ///
    /// - parameter remoteValue: The Remote Config value for a remote key, or `nil` when Remote Config
    ///   has none, which leaves the flag as it is.
    /// - returns: Whether any flag was turned on or off.
    @discardableResult
    static func applyRemoteValues(_ remoteValue: (_ remoteKey: String) -> Bool?, notificationCenter: NotificationCenter = .default) -> Bool {
        var didChange = false
        for flag in allCases {
            guard let remoteKey = flag.remoteKey, let value = remoteValue(remoteKey) else { continue }
            let wasEnabled = flag.enabled
            do {
                FileLog.shared.console("Override \(flag): \(value)")
                try FeatureFlagOverrideStore().override(flag, withValue: value)
            } catch {
                FileLog.shared.addMessage("Failed to set remote feature flag \(flag): \(error)")
            }
            if flag.enabled != wasEnabled {
                FileLog.shared.addMessage("Remote Config turned \(flag) \(flag.enabled ? "on" : "off")")
                didChange = true
            }
        }
        if didChange {
            notificationCenter.post(name: .featureFlagsDidChange, object: nil)
        }
        return didChange
    }
}
