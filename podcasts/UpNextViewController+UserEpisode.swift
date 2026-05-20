import PocketCastsDataModel
import UIKit

extension UpNextViewController: UserEpisodeDetailProtocol {
    func showEdit(userEpisode: UserEpisode) {
        let editVC = AddCustomViewController(episode: userEpisode)
        navigationController?.pushViewController(editVC, animated: true)
    }

    func showDeleteConfirmation(userEpisode: UserEpisode) {
        UserEpisodeManager.presentDeleteOptions(episode: userEpisode, from: self)
    }

    func showUpgradeRequired() {
        NavigationManager.sharedManager.showUpsellView(from: self, source: .unknown)
    }

    func userEpisodeDetailClosed() {
        userEpisodeDetailVC = nil
    }
}
