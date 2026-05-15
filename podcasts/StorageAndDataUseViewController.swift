import PocketCastsUtils
import UIKit

class StorageAndDataUseViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            settingsTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCellId)

            settingsTable.rowHeight = UITableView.automaticDimension
            settingsTable.estimatedRowHeight = UITableView.automaticDimension
            settingsTable.estimatedSectionHeaderHeight = UITableView.automaticDimension
            settingsTable.sectionHeaderHeight = UITableView.automaticDimension
            settingsTable.estimatedSectionFooterHeight = UITableView.automaticDimension
            settingsTable.sectionFooterHeight = UITableView.automaticDimension
        }
    }

    private let usageSection = 0
    private let dataUseSection = 1
    private let switchCellId = "SwitchCell"
    private let disclosureCellId = "DisclosureCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsStorage
        Analytics.track(.settingsStorageShown)
        ManageDownloadsCoordinator.showModalIfNeeded(from: self, source: "storage_and_data_usage")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settingsTable.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)

        if section == usageSection {
            return SettingsTableHeader(frame: headerFrame, title: L10n.settingsStorageUsage)
        }

        return SettingsTableHeader(frame: headerFrame, title: L10n.settingsStorageMobileData)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == usageSection else { return nil }

        let footer = UIView()
        let label = ThemeableLabel()
        label.style = .primaryText02
        label.text = L10n.settingsStorageUsageFooter
        label.numberOfLines = 0
        label.font = UIFont.font(ofSize: 13, weight: .regular, scalingWith: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: footer.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -12)
        ])
        return footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == usageSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell

            cell.cellLabel.text = L10n.downloadedFiles

            let fileSize = EpisodeManager.downloadSizeOfAllEpisodes()
            let sizeAsStr = SizeFormatter.shared.noDecimalFormat(bytes: Int64(fileSize))
            cell.cellSecondaryLabel.text = sizeAsStr.isEmpty ? SizeFormatter.shared.placeholder : sizeAsStr

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell

            cell.cellLabel.text = L10n.settingsStorageDataWarning
            cell.cellSwitch.isOn = !Settings.mobileDataAllowed()

            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(warnWhenNotOnWifiToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == usageSection {
            if indexPath.row == 0 {
                navigationController?.pushViewController(DownloadedFilesViewController(), animated: true)
            }
        }
    }

    @objc private func warnWhenNotOnWifiToggled(_ sender: UISwitch) {
        Settings.setMobileDataAllowed(!sender.isOn, userInitiated: true)
    }
}
