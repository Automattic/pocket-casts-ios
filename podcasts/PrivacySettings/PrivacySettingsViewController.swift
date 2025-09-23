import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class PrivacySettingsViewController: PCViewController, UITableViewDelegate {
    private let legacyDataSource = PrivacySettingsLegacyDataSource()
    private let dataSource = PrivacySettingsDataSource()

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            legacyDataSource.registerCells(for: settingsTable)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsPrivacy
        settingsTable.rowHeight = UITableView.automaticDimension
        settingsTable.dataSource = legacyDataSource
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settingsTable.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Analytics.track(.privacySettingsShown)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 2, 5:
            NavigationManager.sharedManager.navigateTo(NavigationManager.showPrivacyPolicyPageKey, data: nil)
        default:
            break
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}
