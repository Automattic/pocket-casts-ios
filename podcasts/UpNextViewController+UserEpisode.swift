import PocketCastsDataModel
import UIKit

extension UpNextViewController: UserEpisodeDetailProtocol {
    func showEdit(userEpisode: UserEpisode) {
        let editVC = AddCustomViewController(episode: userEpisode)
        navigationController?.pushViewController(editVC, animated: true)
    }

    func showDeleteConfirmation(userEpisode: UserEpisode) {
        UserEpisodeManager.presentDeleteOptions(episode: userEpisode, preferredStatusBarStyle: preferredStatusBarStyle, themeOverride: nil)
        dismiss(animated: true, completion: nil)
    }

    func showUpgradeRequired() {
        NavigationManager.sharedManager.showUpsellView(from: self, source: .unknown)
    }

    func userEpisodeDetailClosed() {
        userEpisodeDetailVC = nil
    }
}
