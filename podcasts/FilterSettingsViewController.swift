import UIKit

class FilterSettingsViewController: UIViewController {
    var filterToEdit: EpisodeFilter!
    @IBOutlet open var tableView: UITableView!

    @IBAction func showResultsTapped(_ sender: AnyObject) {
        func saveFilterAndNotify() {
            filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
            DataManager.sharedManager.save(filter: filterToEdit)
            NotificationCenter.postNotificationOnMainThread(Constants.Notifications.filterChanged.rawValue, object: filterToEdit)
        }
        navigationController?.popViewController(animated: true)
    }
}
