import PocketCastsServer
import UIKit

extension WhatsNewAction.Kind {
    @MainActor
    func perform() {
        switch self {
        case .createPlaylist:
            NavigationManager.shared.navigateTo(NavigationManager.filterAddKey, data: nil)
        case .openDiscover:
            NavigationManager.shared.navigateTo(NavigationManager.discoverPageKey, data: nil)
        case .openPlaylists:
            NavigationManager.shared.navigateTo(NavigationManager.filterPageKey, data: nil)
        case .openPodcasts:
            NavigationManager.shared.navigateTo(NavigationManager.podcastListPageKey, data: nil)
        case .openProfile:
            NavigationManager.shared.navigateTo(NavigationManager.settingsProfileKey, data: nil)
        case .openSettings:
            NavigationManager.shared.navigateTo(NavigationManager.settingsPageKey, data: nil)
        case .openUpNext:
            NavigationManager.shared.navigateTo(NavigationManager.upNextPageKey, data: nil)
        case .openUpsell:
            guard let controller = SceneHelper.rootViewController() else { return }
            NavigationManager.shared.showUpsellView(from: controller, source: .whatsNew)
        case .openLink(let url):
            UIApplication.shared.openSafariVCIfPossible(url)
        }
    }
}
