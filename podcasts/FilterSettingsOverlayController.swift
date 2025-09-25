import PocketCastsDataModel
import UIKit

class FilterSettingsOverlayController: LargeNavBarViewController, AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .unknown
    }

    var filterToEdit: EpisodeFilter!
    @IBOutlet open var tableView: ThemeableTable! {
        didSet {
            tableView.themeStyle = .primaryUi01
        }
    }

    @IBOutlet open var titleLabel: UILabel!
    @IBOutlet open var saveButton: UIButton! {
        didSet {
            saveButton.backgroundColor = filterToEdit.playlistColor()
            saveButton.layer.cornerRadius = 12
            saveButton.setTitleColor(ThemeColor.primaryInteractive02(), for: .normal)
            saveButton.setTitle(L10n.filterUpdate, for: .normal)
        }
    }

    @IBAction func saveTapped(_ sender: AnyObject) {
        saveFilter()
        dismissViewController()
    }

    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    func saveFilter() {
        filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filterToEdit)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filterToEdit)

        if !filterToEdit.isNew {
            Analytics.track(.filterUpdated, properties: ["group": analyticsSource, "source": "filters"])
        }
    }

    override func handleThemeChanged() {
        saveButton.backgroundColor = filterToEdit.playlistColor()
        saveButton.setTitleColor(ThemeColor.primaryInteractive02(), for: .normal)
        setupLargeTitle()
        tableView.reloadData()
    }

    func addTableViewHeader() {
        let headerView = ThemeableView()
        headerView.style = .primaryUi01
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 26)
        headerView.layoutIfNeeded()
        tableView.tableHeaderView = headerView
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
