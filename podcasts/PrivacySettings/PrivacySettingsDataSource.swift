import UIKit

class PrivacySettingsDataSource: NSObject, UITableViewDataSource {
    private let switchCellId = "SwitchCell"
    private let themeableCellId = "ThemeableCell"
    private let themeableCellWithoutSelectionId = "ThemeableCellWithoutSelectionId"

    func registerCells(for tableView: UITableView) {
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
        tableView.register(ThemeableCell.self, forCellReuseIdentifier: themeableCellId)
        tableView.register(ThemeableCellWithoutSelection.self, forCellReuseIdentifier: themeableCellWithoutSelectionId)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellWithoutSelectionId, for: indexPath) as! ThemeableCellWithoutSelection
            cell.style = .primaryUi02
            cell.textLabel?.textColor = ThemeColor.primaryText02()
            cell.textLabel?.text = L10n.settingsCollectInformationAdditionalInformation
            cell.textLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.numberOfLines = 0
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.settingsFirstPartyAnalytics
            cell.cellSwitch.isOn = !Settings.analyticsOptOut()
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(pushToggled(_:)), for: UIControl.Event.valueChanged)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellWithoutSelectionId, for: indexPath) as! ThemeableCellWithoutSelection
            cell.style = .primaryUi02
            cell.imageView?.image = UIImage()
            cell.textLabel?.textColor = ThemeColor.primaryText02()
            cell.textLabel?.text = L10n.settingsAllowCollectionFirstParty
            cell.textLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.numberOfLines = 0
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellId, for: indexPath) as! ThemeableCell
            cell.textLabel?.textColor = ThemeColor.primaryInteractive01()
            cell.textLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.text = L10n.settingsReadPrivacyPolicy
            return cell
        }
    }

    @objc private func pushToggled(_ sender: UISwitch) {
        if sender.isOn {
            Analytics.shared.optInOfAnalytics()
        } else {
            Analytics.shared.optOutOfAnalytics()
        }
    }
}

private class ThemeableCellWithoutSelection: ThemeableCell {
    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
