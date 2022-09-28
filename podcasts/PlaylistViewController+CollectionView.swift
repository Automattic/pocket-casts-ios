import PocketCastsDataModel
import PocketCastsUtils
import UIKit

extension PlaylistViewController: FilterChipActionDelegate {
    func presentingViewController() -> UIViewController {
        self
    }

    func starredChipSelected() {
        tableView.reloadData()
    }
}
