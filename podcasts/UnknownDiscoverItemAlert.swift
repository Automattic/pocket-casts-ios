import Foundation

#if DEBUG
enum UnknownDiscoverItemAlert {
    private static let versionKey = "DebugUnknownDiscoverItemsVersion"
    private static let itemsKey = "DebugUnknownDiscoverItems"

    static func showIfNeeded(type: String?, summaryStyle: String?, expandedStyle: String?) {
        let item = "\(type ?? "unknown") / \(summaryStyle ?? "unknown") / \(expandedStyle ?? "unknown")"

        guard markAsSeenIfNeeded(item) else { return }

        let message = """
        The Discover feed returned an item this build can't render:

        type: \(type ?? "unknown")
        summaryStyle: \(summaryStyle ?? "unknown")
        expandedStyle: \(expandedStyle ?? "unknown")

        The item was skipped. This alert only appears in DEBUG builds, once per item and app version.
        """

        DispatchQueue.main.async {
            SJUIUtils.showAlert(title: "Unknown Discover Item (DEBUG)", message: message, from: SceneHelper.rootViewController())
        }
    }

    private static func markAsSeenIfNeeded(_ item: String) -> Bool {
        let defaults = UserDefaults.standard
        let version = Settings.appVersion()

        if defaults.string(forKey: versionKey) != version {
            defaults.set(version, forKey: versionKey)
            defaults.removeObject(forKey: itemsKey)
        }

        var seen = defaults.stringArray(forKey: itemsKey) ?? []
        guard !seen.contains(item) else { return false }

        seen.append(item)
        defaults.set(seen, forKey: itemsKey)
        return true
    }
}
#endif
