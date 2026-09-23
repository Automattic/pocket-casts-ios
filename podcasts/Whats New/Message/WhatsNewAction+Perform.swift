import PocketCastsServer
import UIKit

extension WhatsNewAction.Kind {
    @MainActor
    func perform() {
        switch self {
        case .createPlaylist:
            NavigationManager.shared.navigateTo(NavigationManager.filterAddKey, data: nil)
        case .openLink(let url):
            UIApplication.shared.openSafariVCIfPossible(url)
        }
    }
}
