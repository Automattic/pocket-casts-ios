import PocketCastsServer
import UIKit

extension WhatsNewAction.Kind {
    @MainActor
    func perform() {
        switch self {
        case .createPlaylist:
            NavigationManager.sharedManager.navigateTo(NavigationManager.filterAddKey, data: nil)
        case .openLink(let url):
            UIApplication.shared.openSafariVCIfPossible(url)
        }
    }
}
