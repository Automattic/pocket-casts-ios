import PocketCastsDataModel
import PocketCastsServer
import UIKit

class PrivacySettingsViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    private let switchCellId = "SwitchCell"
    private let disclosureCellId = "DisclosureCell"

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsPrivacy
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settingsTable.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Analytics.track(.privacySettingsShown)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
        cell.cellLabel.text = L10n.settingsCollectInformation
        cell.cellSwitch.isOn = !Settings.analyticsOptOut()

        cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
        cell.cellSwitch.addTarget(self, action: #selector(pushToggled(_:)), for: UIControl.Event.valueChanged)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        L10n.settingsCollectInformationAdditionalInformation
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    @objc private func pushToggled(_ sender: UISwitch) {
        if sender.isOn {
            Analytics.shared.optInOfAnalytics()
        }
        else {
            Analytics.shared.optOutOfAnalytics()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}
