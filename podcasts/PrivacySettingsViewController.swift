import PocketCastsDataModel
import PocketCastsServer
import UIKit

class PrivacySettingsViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    private let switchCellId = "SwitchCell"
    private let themeableCellId = "ThemeableCell"
    private let themeableCellWithoutSelectionId = "ThemeableCellWithoutSelectionId"

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            settingsTable.register(ThemeableCell.self, forCellReuseIdentifier: themeableCellId)
            settingsTable.register(ThemeableCellWithoutSelection.self, forCellReuseIdentifier: themeableCellWithoutSelectionId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsPrivacy
        settingsTable.rowHeight = UITableView.automaticDimension
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
        3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.settingsCollectInformation
            cell.cellSwitch.isOn = !Settings.analyticsOptOut()

            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(pushToggled(_:)), for: UIControl.Event.valueChanged)

            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellWithoutSelectionId, for: indexPath) as! ThemeableCellWithoutSelection
            cell.style = .primaryUi02
            cell.imageView?.image = UIImage()
            cell.textLabel?.textColor = ThemeColor.primaryText02()
            cell.textLabel?.text = L10n.settingsCollectInformationAdditionalInformation
            cell.textLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.numberOfLines = 0
            return cell

        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellId, for: indexPath) as! ThemeableCell
            cell.imageView?.image = UIImage()
            cell.textLabel?.textColor = ThemeColor.primaryInteractive01()
            cell.textLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.text = L10n.settingsReadPrivacyPolicy
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == 2 else { return }

        NavigationManager.sharedManager.navigateTo(NavigationManager.showPrivacyPolicyPageKey, data: nil)
    }

    @objc private func pushToggled(_ sender: UISwitch) {
        if sender.isOn {
            Analytics.shared.optInOfAnalytics()
        } else {
            Analytics.shared.optOutOfAnalytics()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}

private class ThemeableCellWithoutSelection: ThemeableCell {
    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
