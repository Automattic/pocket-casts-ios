import PocketCastsServer
import PocketCastsUtils

/// What a What's New action asks the app to do.
///
/// The catalog names a behaviour rather than pointing at a destination, so it can't ask the app to
/// open whatever a URL happens to hold. Each client maps the event names it implements to somewhere
/// of its own; an event this build has never heard of costs its page a button and nothing else.
enum WhatsNewActionEvent: String {
    case openPodcasts = "open_podcasts"
    case openDiscover = "open_discover"
    case openUpNext = "open_up_next"
    case openPlaylists = "open_playlists"
    case openProfile = "open_profile"
    case openSettings = "open_settings"
    case openUpsell = "open_upsell"

    init?(action: WhatsNewAction) {
        guard let event = WhatsNewActionEvent(rawValue: action.event) else {
            FileLog.shared.addMessage("What's New: dropping an action for an event this build doesn't implement: \(action.event)")
            return nil
        }
        self = event
    }

    @MainActor
    func perform() {
        switch self {
        case .openPodcasts:
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastListPageKey, data: nil)
        case .openDiscover:
            NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey, data: nil)
        case .openUpNext:
            NavigationManager.sharedManager.navigateTo(NavigationManager.upNextPageKey, data: nil)
        case .openPlaylists:
            NavigationManager.sharedManager.navigateTo(NavigationManager.filterPageKey, data: nil)
        case .openProfile:
            NavigationManager.sharedManager.navigateTo(NavigationManager.settingsProfileKey, data: nil)
        case .openSettings:
            NavigationManager.sharedManager.navigateTo(NavigationManager.settingsPageKey, data: nil)
        case .openUpsell:
            guard let viewController = SceneHelper.rootViewController() else { return }
            NavigationManager.sharedManager.navigateTo(NavigationManager.subscriptionRequiredPageKey,
                                                       data: ["source": PlusUpgradeViewSource.whatsNew,
                                                              NavigationManager.subscriptionUpgradeVCKey: viewController])
        }
    }
}
